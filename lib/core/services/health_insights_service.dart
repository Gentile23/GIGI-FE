import 'package:flutter/foundation.dart';

import 'health_integration_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/biometric_service.dart';
import '../../data/models/biometric_model.dart';
import '../../data/services/workout_log_service.dart';

/// ═══════════════════════════════════════════════════════════
/// HEALTH INSIGHTS SERVICE
/// Analyzes health data to generate personalized insights and trends
/// ═══════════════════════════════════════════════════════════
class HealthInsightsService {
  static final HealthInsightsService _instance =
      HealthInsightsService._internal();
  factory HealthInsightsService() => _instance;
  HealthInsightsService._internal();

  final HealthIntegrationService _healthService = HealthIntegrationService();
  final WorkoutLogService _workoutLogService = WorkoutLogService(ApiClient());
  final BiometricService _biometricService = BiometricService(ApiClient());

  Future<bool> initialize() async {
    await _healthService.initialize();
    return _healthService.isAuthorized;
  }

  bool get isConnected => _healthService.isAuthorized;

  String get platformName => _healthService.platformName;

  bool get isAndroidPlatform => platformName == 'Health Connect';

  Future<bool> connectHealth() async {
    await _healthService.initialize();
    if (_healthService.isAuthorized) {
      return true;
    }
    return _healthService.requestPermissions();
  }

  Future<bool> isHealthConnectInstalled() async {
    await _healthService.initialize();
    return _healthService.isHealthConnectInstalled();
  }

  Future<void> installHealthConnect() async {
    await _healthService.installHealthConnect();
  }

  // ═══════════════════════════════════════════════════════════
  // WEEKLY REPORT DATA
  // ═══════════════════════════════════════════════════════════

  /// Generate a complete weekly health report
  Future<WeeklyHealthReport?> generateWeeklyReport() async {
    final isAuthorized = await initialize();
    if (!isAuthorized) return null;

    // Get current week data
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Collect health metrics
    final sleepResult = await _getSleepDataForWeek(weekStart);
    final sleepData = sleepResult.dailyHours;
    final stepsData = await _getStepsDataForWeek(weekStart);
    final heartRateData = await _getHeartRateData();
    final hasSleepData = sleepResult.hasData;
    final hasStepsData = stepsData.values.any((value) => value > 0);
    final hasHeartRateData = heartRateData != null;
    final workoutResult = await _getWorkoutDataForWeek();

    // Generate insights
    final insights = _generateInsights(
      sleepData,
      stepsData,
      heartRateData,
      workoutResult.completedCount,
      hasWorkoutData: workoutResult.isAvailable,
    );

    // Calculate trends
    final sleepTrend = _calculateTrend(sleepData.values.toList());

    return WeeklyHealthReport(
      periodStart: weekStart,
      periodEnd: now,
      sleep: SleepSummary(
        avgHours: _average(sleepData.values.toList()),
        trend: sleepTrend,
        bestDay: _getBestDay(sleepData),
        worstDay: _getWorstDay(sleepData),
        dailyHours: sleepData,
      ),
      activity: ActivitySummary(
        totalSteps: stepsData.values.fold(0, (a, b) => a + b),
        avgDailySteps: (stepsData.values.fold(0, (a, b) => a + b) / 7).round(),
        workoutsCompleted: workoutResult.completedCount,
        dailySteps: stepsData,
      ),
      heartRate: HeartRateSummary(
        restingAvg: heartRateData ?? 0,
        trend: 'stable',
      ),
      insights: insights,
      aiTip: _generateWeeklyTip(
        sleepData,
        stepsData,
        workoutResult.completedCount,
      ),
      hasHealthData: hasSleepData || hasStepsData || hasHeartRateData,
      hasSleepData: hasSleepData,
      hasStepsData: hasStepsData,
      hasHeartRateData: hasHeartRateData,
      hasWorkoutData: workoutResult.isAvailable,
      sleepDataSource: sleepResult.source,
      workoutDataStatus: workoutResult.isAvailable ? 'available' : 'error',
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TREND INSIGHTS
  // ═══════════════════════════════════════════════════════════

  /// Get list of actionable trend insights for the dashboard
  Future<List<TrendInsight>> getTrendInsights() async {
    final isAuthorized = await initialize();
    if (!isAuthorized) return [];

    final insights = <TrendInsight>[];

    // Sleep insight
    final sleepHours = await _healthService.getSleepHours(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (sleepHours != null) {
      if (sleepHours >= 7) {
        insights.add(
          TrendInsight(
            emoji: '😴',
            title: 'Sonno eccellente!',
            description:
                'Hai dormito ${sleepHours.toStringAsFixed(1)}h. Perfetto per il recupero muscolare.',
            type: InsightType.positive,
            metric: '${sleepHours.toStringAsFixed(1)}h',
          ),
        );
      } else if (sleepHours < 6) {
        insights.add(
          TrendInsight(
            emoji: '⚠️',
            title: 'Sonno insufficiente',
            description:
                'Solo ${sleepHours.toStringAsFixed(1)}h di sonno. Il recupero potrebbe essere compromesso.',
            type: InsightType.warning,
            metric: '${sleepHours.toStringAsFixed(1)}h',
          ),
        );
      }
    }

    // Steps insight
    final steps = await _healthService.getStepsToday();
    if (steps != null) {
      if (steps >= 10000) {
        insights.add(
          TrendInsight(
            emoji: '🚶',
            title: 'Obiettivo passi raggiunto!',
            description: '$steps passi oggi. Ottima attività quotidiana.',
            type: InsightType.positive,
            metric: '${(steps / 1000).toStringAsFixed(1)}k',
          ),
        );
      } else if (steps < 5000) {
        insights.add(
          TrendInsight(
            emoji: '👟',
            title: 'Muoviti di più',
            description:
                'Solo $steps passi. Una camminata di 15 min aiuterebbe.',
            type: InsightType.suggestion,
            metric: '${(steps / 1000).toStringAsFixed(1)}k',
          ),
        );
      }
    }

    // Heart rate insight
    final hr = await _healthService.getRestingHeartRate();
    if (hr != null) {
      if (hr < 60) {
        insights.add(
          TrendInsight(
            emoji: '💓',
            title: 'Cuore da atleta',
            description:
                'HR a riposo di $hr bpm. Eccellente fitness cardiovascolare!',
            type: InsightType.positive,
            metric: '$hr bpm',
          ),
        );
      } else if (hr > 80) {
        insights.add(
          TrendInsight(
            emoji: '❤️',
            title: 'HR elevato',
            description:
                'Battito a riposo $hr bpm. Possibile stress o stanchezza.',
            type: InsightType.warning,
            metric: '$hr bpm',
          ),
        );
      }
    }

    // Weight insight
    final weight = await _healthService.getCurrentWeight();
    if (weight != null) {
      insights.add(
        TrendInsight(
          emoji: '⚖️',
          title: 'Peso attuale',
          description: '${weight.toStringAsFixed(1)} kg registrato.',
          type: InsightType.neutral,
          metric: '${weight.toStringAsFixed(1)}kg',
        ),
      );
    }

    return insights;
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════

  Future<_SleepWeekDataResult> _getSleepDataForWeek(DateTime weekStart) async {
    final healthData = await _getSleepDataFromHealthForWeek(weekStart);
    final hasHealthSleepData = healthData.values.any((value) => value > 0);
    if (hasHealthSleepData) {
      return _SleepWeekDataResult(
        dailyHours: healthData,
        hasData: true,
        source: 'health',
      );
    }

    final fallbackData = await _getSleepDataFromBackendForWeek(weekStart);
    final hasFallbackData = fallbackData.values.any((value) => value > 0);

    if (hasFallbackData) {
      if (kDebugMode) {
        debugPrint('health_sleep_missing -> sleep_backend_fallback_used');
      }
      return _SleepWeekDataResult(
        dailyHours: fallbackData,
        hasData: true,
        source: 'backend_fallback',
      );
    }

    return _SleepWeekDataResult(
      dailyHours: healthData,
      hasData: false,
      source: 'none',
    );
  }

  Future<Map<String, double>> _getSleepDataFromHealthForWeek(
    DateTime weekStart,
  ) async {
    final data = <String, double>{};
    final days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final sleep = await _healthService.getSleepHours(date);
      data[days[i]] = sleep ?? 0;
    }
    return data;
  }

  Future<Map<String, double>> _getSleepDataFromBackendForWeek(
    DateTime weekStart,
  ) async {
    final data = <String, double>{};
    final days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    for (final day in days) {
      data[day] = 0;
    }

    try {
      final history = await _biometricService.getSleepHistory(days: 14);
      final sessions = history?['sessions'] is List<SleepSession>
          ? history!['sessions'] as List<SleepSession>
          : <SleepSession>[];

      if (sessions.isEmpty) {
        return data;
      }

      for (int index = 0; index < 7; index++) {
        final dayStart = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).add(Duration(days: index));
        final dayEnd = dayStart.add(const Duration(days: 1));
        double totalMinutes = 0;

        for (final session in sessions) {
          totalMinutes += _getOverlapDuration(
            rangeStart: session.startTime,
            rangeEnd: session.endTime,
            windowStart: dayStart,
            windowEnd: dayEnd,
          ).inMinutes;
        }

        data[days[index]] = totalMinutes > 0 ? totalMinutes / 60 : 0;
      }
    } catch (_) {
      return data;
    }

    return data;
  }

  Future<Map<String, int>> _getStepsDataForWeek(DateTime weekStart) async {
    final data = <String, int>{};
    final days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final steps = await _healthService.getStepsForDate(date);
      data[days[i]] = steps ?? 0;
    }
    return data;
  }

  Future<int?> _getHeartRateData() async {
    return await _healthService.getRestingHeartRate();
  }

  Future<_WorkoutDataResult> _getWorkoutDataForWeek() async {
    try {
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final logs = await _workoutLogService.getWorkoutLogs(
        startDate: weekStart,
        endDate: weekEnd,
        perPage: 100,
      );

      return _WorkoutDataResult(
        completedCount: logs.where((log) => log.completedAt != null).length,
        isAvailable: true,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('workout_logs_fetch_failed: $error');
      }
      return const _WorkoutDataResult(completedCount: 0, isAvailable: false);
    }
  }

  List<String> _generateInsights(
    Map<String, double> sleep,
    Map<String, int> steps,
    int? hr,
    int workouts, {
    required bool hasWorkoutData,
  }) {
    final insights = <String>[];

    final hasSleepData = sleep.values.any((value) => value > 0);
    if (hasSleepData) {
      final avgSleep = _average(sleep.values.toList());
      if (avgSleep < 7) {
        insights.add(
          'Il tuo sonno medio è ${avgSleep.toStringAsFixed(1)}h. Punta a 7-8 ore per massimizzare il recupero.',
        );
      } else {
        insights.add(
          'Ottimo! Dormi in media ${avgSleep.toStringAsFixed(1)}h a notte. Continua così!',
        );
      }
    } else {
      insights.add('Nessun dato sonno disponibile questa settimana da Health.');
    }

    final hasStepsData = steps.values.any((value) => value > 0);
    if (hasStepsData) {
      final avgSteps = steps.values.fold(0, (a, b) => a + b) ~/ 7;
      if (avgSteps >= 10000) {
        insights.add(
          'Media di $avgSteps passi/giorno. Eccellente livello di attività!',
        );
      } else {
        insights.add(
          'Media di $avgSteps passi/giorno. Prova ad aggiungere una camminata di 15 min.',
        );
      }
    } else {
      insights.add('Nessun dato passi disponibile questa settimana da Health.');
    }

    if (!hasWorkoutData) {
      insights.add(
        'Non siamo riusciti a recuperare i workout completati di questa settimana.',
      );
    } else if (workouts >= 4) {
      insights.add(
        '$workouts allenamenti completati. Sei sulla strada giusta! 💪',
      );
    } else {
      insights.add('Workout completati questa settimana: $workouts.');
    }

    if (hr != null) {
      insights.add('Frequenza cardiaca a riposo rilevata: $hr bpm.');
    }

    return insights;
  }

  String _generateWeeklyTip(
    Map<String, double> sleep,
    Map<String, int> steps,
    int workouts,
  ) {
    final hasSleepData = sleep.values.any((value) => value > 0);
    final hasStepsData = steps.values.any((value) => value > 0);
    if (!hasSleepData && !hasStepsData) {
      return 'Abbiamo pochi dati Health questa settimana: controlla i permessi Apple Health e riapri l’app.';
    }

    final avgSleep = _average(sleep.values.toList());

    if (avgSleep < 6.5) {
      return 'Questa settimana focus sul sonno: prova a spegnere gli schermi 1 ora prima di dormire.';
    } else if (workouts < 3) {
      return 'Aumenta la frequenza degli allenamenti: anche 20 minuti contano!';
    } else {
      return 'Stai andando alla grande! Mantieni questa costanza per vedere risultati.';
    }
  }

  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';

    final firstHalf = values.sublist(0, values.length ~/ 2);
    final secondHalf = values.sublist(values.length ~/ 2);

    final firstAvg = _average(firstHalf);
    final secondAvg = _average(secondHalf);

    if (secondAvg > firstAvg * 1.05) return 'up';
    if (secondAvg < firstAvg * 0.95) return 'down';
    return 'stable';
  }

  String _getBestDay(Map<String, double> data) {
    String best = data.keys.first;
    double max = data.values.first;
    data.forEach((day, value) {
      if (value > max) {
        max = value;
        best = day;
      }
    });
    return best;
  }

  String _getWorstDay(Map<String, double> data) {
    String worst = data.keys.first;
    double min = data.values.first;
    data.forEach((day, value) {
      if (value < min && value > 0) {
        min = value;
        worst = day;
      }
    });
    return worst;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    final nonZero = values.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.reduce((a, b) => a + b) / nonZero.length;
  }

  Duration _getOverlapDuration({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final overlapStart = rangeStart.isAfter(windowStart)
        ? rangeStart
        : windowStart;
    final overlapEnd = rangeEnd.isBefore(windowEnd) ? rangeEnd : windowEnd;

    if (!overlapEnd.isAfter(overlapStart)) {
      return Duration.zero;
    }
    return overlapEnd.difference(overlapStart);
  }
}

// ═══════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════

class WeeklyHealthReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final SleepSummary sleep;
  final ActivitySummary activity;
  final HeartRateSummary heartRate;
  final List<String> insights;
  final String aiTip;
  final bool hasHealthData;
  final bool hasSleepData;
  final bool hasStepsData;
  final bool hasHeartRateData;
  final bool hasWorkoutData;
  final String sleepDataSource;
  final String workoutDataStatus;

  WeeklyHealthReport({
    required this.periodStart,
    required this.periodEnd,
    required this.sleep,
    required this.activity,
    required this.heartRate,
    required this.insights,
    required this.aiTip,
    required this.hasHealthData,
    required this.hasSleepData,
    required this.hasStepsData,
    required this.hasHeartRateData,
    required this.hasWorkoutData,
    required this.sleepDataSource,
    required this.workoutDataStatus,
  });
}

class SleepSummary {
  final double avgHours;
  final String trend; // up, down, stable
  final String bestDay;
  final String worstDay;
  final Map<String, double> dailyHours;

  SleepSummary({
    required this.avgHours,
    required this.trend,
    required this.bestDay,
    required this.worstDay,
    required this.dailyHours,
  });
}

class ActivitySummary {
  final int totalSteps;
  final int avgDailySteps;
  final int workoutsCompleted;
  final Map<String, int> dailySteps;

  ActivitySummary({
    required this.totalSteps,
    required this.avgDailySteps,
    required this.workoutsCompleted,
    required this.dailySteps,
  });
}

class HeartRateSummary {
  final int restingAvg;
  final String trend;

  HeartRateSummary({required this.restingAvg, required this.trend});
}

class TrendInsight {
  final String emoji;
  final String title;
  final String description;
  final InsightType type;
  final String metric;

  TrendInsight({
    required this.emoji,
    required this.title,
    required this.description,
    required this.type,
    required this.metric,
  });
}

enum InsightType { positive, warning, suggestion, neutral }

class _SleepWeekDataResult {
  final Map<String, double> dailyHours;
  final bool hasData;
  final String source;

  const _SleepWeekDataResult({
    required this.dailyHours,
    required this.hasData,
    required this.source,
  });
}

class _WorkoutDataResult {
  final int completedCount;
  final bool isAvailable;

  const _WorkoutDataResult({
    required this.completedCount,
    required this.isAvailable,
  });
}
