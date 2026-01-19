// Unit tests for Health Integration
import 'package:flutter_test/flutter_test.dart';

// Mock HealthData class
class HealthData {
  final DateTime date;
  final int? steps;
  final double? heartRate;
  final double? sleepHours;
  final double? weight;
  final int? caloriesBurned;

  HealthData({
    required this.date,
    this.steps,
    this.heartRate,
    this.sleepHours,
    this.weight,
    this.caloriesBurned,
  });

  bool get hasSteps => steps != null && steps! > 0;
  bool get hasHeartRate => heartRate != null && heartRate! > 0;
  bool get hasSleepData => sleepHours != null && sleepHours! > 0;

  int get stepsGoalProgress {
    if (steps == null) return 0;
    return ((steps! / 10000) * 100).clamp(0, 100).toInt();
  }

  String get sleepQuality {
    if (sleepHours == null) return 'unknown';
    if (sleepHours! >= 7 && sleepHours! <= 9) return 'good';
    if (sleepHours! >= 6 && sleepHours! < 7) return 'fair';
    if (sleepHours! > 9) return 'excessive';
    return 'poor';
  }

  String get heartRateZone {
    if (heartRate == null) return 'unknown';
    if (heartRate! < 60) return 'low';
    if (heartRate! >= 60 && heartRate! <= 100) return 'normal';
    return 'elevated';
  }
}

// Mock HealthSyncStatus class
class HealthSyncStatus {
  final bool isConnected;
  final DateTime? lastSync;
  final String platform; // 'apple_health', 'health_connect'
  final List<String> enabledMetrics;

  HealthSyncStatus({
    required this.isConnected,
    this.lastSync,
    required this.platform,
    this.enabledMetrics = const [],
  });

  bool get needsSync {
    if (!isConnected || lastSync == null) return false;
    return DateTime.now().difference(lastSync!).inHours > 1;
  }

  bool get hasStepsEnabled => enabledMetrics.contains('steps');
  bool get hasHeartRateEnabled => enabledMetrics.contains('heart_rate');
  bool get hasSleepEnabled => enabledMetrics.contains('sleep');
  bool get hasWeightEnabled => enabledMetrics.contains('weight');
  bool get hasCaloriesEnabled => enabledMetrics.contains('calories');

  String get platformDisplayName {
    switch (platform) {
      case 'apple_health':
        return 'Apple Health';
      case 'health_connect':
        return 'Health Connect';
      default:
        return 'Unknown';
    }
  }
}

// Mock WeeklyHealthSummary class
class WeeklyHealthSummary {
  final List<HealthData> dailyData;

  WeeklyHealthSummary({required this.dailyData});

  int get totalSteps {
    return dailyData.fold(0, (sum, d) => sum + (d.steps ?? 0));
  }

  double get avgStepsPerDay {
    if (dailyData.isEmpty) return 0;
    return totalSteps / dailyData.length;
  }

  double get avgSleepHours {
    final sleepDays = dailyData.where((d) => d.hasSleepData).toList();
    if (sleepDays.isEmpty) return 0;
    final total = sleepDays.fold(0.0, (sum, d) => sum + d.sleepHours!);
    return total / sleepDays.length;
  }

  double get avgHeartRate {
    final hrDays = dailyData.where((d) => d.hasHeartRate).toList();
    if (hrDays.isEmpty) return 0;
    final total = hrDays.fold(0.0, (sum, d) => sum + d.heartRate!);
    return total / hrDays.length;
  }

  int get daysWithStepsGoalMet {
    return dailyData.where((d) => (d.steps ?? 0) >= 10000).length;
  }

  int get daysWithGoodSleep {
    return dailyData.where((d) => d.sleepQuality == 'good').length;
  }
}

void main() {
  group('HealthData Model', () {
    test('HealthData creation', () {
      final data = HealthData(
        date: DateTime(2026, 1, 15),
        steps: 8500,
        heartRate: 72,
        sleepHours: 7.5,
      );

      expect(data.steps, 8500);
      expect(data.heartRate, 72);
      expect(data.sleepHours, 7.5);
    });

    test('hasSteps check', () {
      expect(HealthData(date: DateTime.now(), steps: 5000).hasSteps, true);
      expect(HealthData(date: DateTime.now(), steps: 0).hasSteps, false);
      expect(HealthData(date: DateTime.now()).hasSteps, false);
    });

    test('hasHeartRate check', () {
      expect(
        HealthData(date: DateTime.now(), heartRate: 72).hasHeartRate,
        true,
      );
      expect(
        HealthData(date: DateTime.now(), heartRate: 0).hasHeartRate,
        false,
      );
      expect(HealthData(date: DateTime.now()).hasHeartRate, false);
    });

    test('Steps goal progress', () {
      expect(
        HealthData(date: DateTime.now(), steps: 10000).stepsGoalProgress,
        100,
      );
      expect(
        HealthData(date: DateTime.now(), steps: 5000).stepsGoalProgress,
        50,
      );
      expect(
        HealthData(date: DateTime.now(), steps: 15000).stepsGoalProgress,
        100,
      ); // Capped
      expect(HealthData(date: DateTime.now()).stepsGoalProgress, 0);
    });

    test('Sleep quality assessment', () {
      expect(
        HealthData(date: DateTime.now(), sleepHours: 8).sleepQuality,
        'good',
      );
      expect(
        HealthData(date: DateTime.now(), sleepHours: 7).sleepQuality,
        'good',
      );
      expect(
        HealthData(date: DateTime.now(), sleepHours: 6.5).sleepQuality,
        'fair',
      );
      expect(
        HealthData(date: DateTime.now(), sleepHours: 5).sleepQuality,
        'poor',
      );
      expect(
        HealthData(date: DateTime.now(), sleepHours: 10).sleepQuality,
        'excessive',
      );
      expect(HealthData(date: DateTime.now()).sleepQuality, 'unknown');
    });

    test('Heart rate zone', () {
      expect(
        HealthData(date: DateTime.now(), heartRate: 55).heartRateZone,
        'low',
      );
      expect(
        HealthData(date: DateTime.now(), heartRate: 72).heartRateZone,
        'normal',
      );
      expect(
        HealthData(date: DateTime.now(), heartRate: 110).heartRateZone,
        'elevated',
      );
      expect(HealthData(date: DateTime.now()).heartRateZone, 'unknown');
    });
  });

  group('HealthSyncStatus Model', () {
    test('HealthSyncStatus creation', () {
      final status = HealthSyncStatus(
        isConnected: true,
        lastSync: DateTime.now(),
        platform: 'health_connect',
        enabledMetrics: ['steps', 'heart_rate', 'sleep'],
      );

      expect(status.isConnected, true);
      expect(status.platform, 'health_connect');
    });

    test('Platform display name', () {
      expect(
        HealthSyncStatus(
          isConnected: true,
          platform: 'apple_health',
        ).platformDisplayName,
        'Apple Health',
      );

      expect(
        HealthSyncStatus(
          isConnected: true,
          platform: 'health_connect',
        ).platformDisplayName,
        'Health Connect',
      );

      expect(
        HealthSyncStatus(
          isConnected: true,
          platform: 'unknown',
        ).platformDisplayName,
        'Unknown',
      );
    });

    test('Enabled metrics checks', () {
      final status = HealthSyncStatus(
        isConnected: true,
        platform: 'health_connect',
        enabledMetrics: ['steps', 'heart_rate'],
      );

      expect(status.hasStepsEnabled, true);
      expect(status.hasHeartRateEnabled, true);
      expect(status.hasSleepEnabled, false);
      expect(status.hasWeightEnabled, false);
    });

    test('Needs sync check', () {
      final recentSync = HealthSyncStatus(
        isConnected: true,
        lastSync: DateTime.now(),
        platform: 'health_connect',
      );
      expect(recentSync.needsSync, false);

      final oldSync = HealthSyncStatus(
        isConnected: true,
        lastSync: DateTime.now().subtract(const Duration(hours: 2)),
        platform: 'health_connect',
      );
      expect(oldSync.needsSync, true);

      final notConnected = HealthSyncStatus(
        isConnected: false,
        platform: 'health_connect',
      );
      expect(notConnected.needsSync, false);
    });
  });

  group('WeeklyHealthSummary Model', () {
    late WeeklyHealthSummary summary;

    setUp(() {
      summary = WeeklyHealthSummary(
        dailyData: [
          HealthData(
            date: DateTime(2026, 1, 1),
            steps: 8000,
            sleepHours: 7.5,
            heartRate: 70,
          ),
          HealthData(
            date: DateTime(2026, 1, 2),
            steps: 12000,
            sleepHours: 8,
            heartRate: 68,
          ),
          HealthData(
            date: DateTime(2026, 1, 3),
            steps: 5000,
            sleepHours: 6,
            heartRate: 75,
          ),
          HealthData(
            date: DateTime(2026, 1, 4),
            steps: 10500,
            sleepHours: 7,
            heartRate: 72,
          ),
          HealthData(
            date: DateTime(2026, 1, 5),
            steps: 9000,
            sleepHours: 8.5,
            heartRate: 69,
          ),
        ],
      );
    });

    test('Total steps calculation', () {
      // 8000 + 12000 + 5000 + 10500 + 9000 = 44500
      expect(summary.totalSteps, 44500);
    });

    test('Average steps per day', () {
      // 44500 / 5 = 8900
      expect(summary.avgStepsPerDay, 8900);
    });

    test('Average sleep hours', () {
      // (7.5 + 8 + 6 + 7 + 8.5) / 5 = 7.4
      expect(summary.avgSleepHours, closeTo(7.4, 0.01));
    });

    test('Average heart rate', () {
      // (70 + 68 + 75 + 72 + 69) / 5 = 70.8
      expect(summary.avgHeartRate, closeTo(70.8, 0.01));
    });

    test('Days with steps goal met (10000+)', () {
      // 12000 and 10500 = 2 days
      expect(summary.daysWithStepsGoalMet, 2);
    });

    test('Days with good sleep', () {
      // 7.5, 8, 7, 8.5 are good (7-9 hours) = 4 days
      // 6 is fair, not good
      expect(summary.daysWithGoodSleep, 4);
    });

    test('Empty data handling', () {
      final empty = WeeklyHealthSummary(dailyData: []);

      expect(empty.totalSteps, 0);
      expect(empty.avgStepsPerDay, 0);
      expect(empty.avgSleepHours, 0);
      expect(empty.avgHeartRate, 0);
      expect(empty.daysWithStepsGoalMet, 0);
    });
  });
}
