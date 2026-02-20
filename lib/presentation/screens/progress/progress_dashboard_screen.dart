import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/progress/interactive_body_silhouette.dart';
import '../../../data/services/api_client.dart';
import 'body_measurements_screen.dart';
import 'progress_photos_screen.dart';
import 'progress_comparison_screen.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import 'package:gigi/l10n/app_localizations.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;

  // Data
  Map<String, dynamic>? _latestMeasurements;
  Map<String, dynamic>? _changes;
  List<dynamic> _measurementsHistory = [];
  List<dynamic> _goals = [];
  int _streak = 0;

  // Workout History Stats
  int _totalWorkouts = 0;
  int _totalSeries = 0;
  int _totalCalories = 0;
  Duration _totalWorkoutTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch measurements data
      final measurementsResponse = await _apiClient.dio.get(
        '/progress/measurements',
      );
      final historyResponse = await _apiClient.dio.get(
        '/progress/measurements/history',
      );

      // Try to fetch goals (may not exist yet)
      dynamic goalsData;
      try {
        final goalsResponse = await _apiClient.dio.get('/progress/goals');
        goalsData = goalsResponse.data;
      } catch (_) {
        goalsData = null;
      }

      if (mounted) {
        final measurementsData = measurementsResponse.data;
        final historyData = historyResponse.data;

        setState(() {
          _latestMeasurements =
              measurementsData['latest'] is Map<String, dynamic>
              ? measurementsData['latest']
              : null;
          _changes = measurementsData['changes'] is Map<String, dynamic>
              ? measurementsData['changes']
              : {};
          _measurementsHistory = historyData['measurements'] ?? [];
          _goals = goalsData?['goals'] ?? [];
          _streak = _calculateStreak();
          _isLoading = false;
        });

        // Load workout history stats
        _loadWorkoutStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateStreak() {
    if (_measurementsHistory.isEmpty) return 0;
    // Calculate consecutive weeks with measurements
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < _measurementsHistory.length && i < 52; i++) {
      final measurement = _measurementsHistory[i] as Map<String, dynamic>;
      final dateStr = measurement['measurement_date'] as String?;
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null) {
          final weeksDiff = now.difference(date).inDays ~/ 7;
          if (weeksDiff <= i + 1) {
            streak++;
          } else {
            break;
          }
        }
      }
    }
    return streak;
  }

  /// Safely parse a value to num (handles both String and num)
  num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Future<void> _loadWorkoutStats() async {
    try {
      final response = await _apiClient.dio.get('/workout-logs');
      if (response.statusCode == 200 && mounted) {
        final logs = response.data['logs'] as List<dynamic>? ?? [];
        int totalWorkouts = logs.length;
        int totalSeries = 0;
        int totalCalories = 0;
        int totalMinutes = 0;

        for (final log in logs) {
          final logData = log as Map<String, dynamic>;
          totalSeries += (logData['total_sets'] as int?) ?? 0;
          totalCalories += (logData['calories_burned'] as int?) ?? 0;
          totalMinutes += (logData['duration_minutes'] as int?) ?? 0;
        }

        setState(() {
          _totalWorkouts = totalWorkouts;
          _totalSeries = totalSeries;
          _totalCalories = totalCalories;
          _totalWorkoutTime = Duration(minutes: totalMinutes);
        });
      }
    } catch (e) {
      debugPrint('Error loading workout stats: $e');
    }
  }

  Widget _buildWorkoutStatsSection() {
    final hours = _totalWorkoutTime.inHours;
    final minutes = _totalWorkoutTime.inMinutes.remainder(60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏋️ ${AppLocalizations.of(context)!.progressStatsTitle}',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CleanCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '💪',
                      '$_totalWorkouts',
                      AppLocalizations.of(context)!.progressWorkouts,
                      CleanTheme.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '🔄',
                      '$_totalSeries',
                      AppLocalizations.of(context)!.progressTotalSets,
                      CleanTheme.accentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '🔥',
                      '$_totalCalories',
                      AppLocalizations.of(context)!.progressCalories,
                      CleanTheme.accentOrange,
                    ),
                  ),
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '⏱️',
                      hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                      AppLocalizations.of(context)!.progressTotalTime,
                      CleanTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutStatItem(
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.progressTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gigi AI Guide
                    _buildGigiInsights(),
                    const SizedBox(height: 20),

                    // Streak & Quick Stats
                    _buildStreakCard(),
                    const SizedBox(height: 20),

                    // Key Changes Summary
                    if (_changes != null && _changes!.isNotEmpty) ...[
                      _buildChangesSection(),
                      const SizedBox(height: 20),
                    ],

                    // Chart Section
                    _buildChartsSection(),
                    const SizedBox(height: 20),

                    // Body Silhouette
                    _buildBodySilhouetteSection(),
                    const SizedBox(height: 20),

                    // Goals Progress
                    _buildGoalsSection(),
                    const SizedBox(height: 20),

                    // Achievements
                    _buildAchievementsSection(),
                    const SizedBox(height: 20),

                    // Workout History Stats
                    _buildWorkoutStatsSection(),
                    const SizedBox(height: 20),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return GestureDetector(
      onTap: () => HapticService.mediumTap(),
      child: LiquidSteelContainer(
        borderRadius: 20,
        enableShine: true,
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Streak info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_streak ${AppLocalizations.of(context)!.weeks}',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: CleanTheme
                                    .primaryColor, // Accent color on dark steel
                              ),
                            ),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.consecutiveMeasurements,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMiniStat(
                          '📏',
                          '${_measurementsHistory.length}',
                          AppLocalizations.of(context)!.measurements,
                        ),
                        const SizedBox(width: 24),
                        _buildMiniStat(
                          '📅',
                          _latestMeasurements != null ? 'Oggi' : '-',
                          AppLocalizations.of(context)!.lastMeasurement,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: (_streak / 12).clamp(0, 1),
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(
                        CleanTheme.primaryColor,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${((_streak / 12) * 100).round()}%',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChangesSection() {
    final changes = _changes ?? {};
    if (changes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📈 ${AppLocalizations.of(context)!.progressChangesTitle}',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProgressComparisonScreen(),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_parseNum(changes['waist_cm']) != null)
                _buildChangeCard(
                  'Vita',
                  _parseNum(changes['waist_cm'])!,
                  '⭕',
                  true,
                ),
              if (_parseNum(changes['bicep_right_cm']) != null)
                _buildChangeCard(
                  'Bicipite',
                  _parseNum(changes['bicep_right_cm'])!,
                  '💪',
                  false,
                ),
              if (_parseNum(changes['chest_cm']) != null)
                _buildChangeCard(
                  'Petto',
                  _parseNum(changes['chest_cm'])!,
                  '👕',
                  false,
                ),
              if (_parseNum(changes['weight_kg']) != null)
                _buildChangeCard(
                  'Peso',
                  _parseNum(changes['weight_kg'])!,
                  '⚖️',
                  true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeCard(
    String label,
    num change,
    String emoji,
    bool lowerIsBetter,
  ) {
    final isPositive = lowerIsBetter ? change < 0 : change > 0;
    final displayChange = change.abs();
    final color = isPositive ? CleanTheme.accentGreen : CleanTheme.accentRed;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
                size: 18,
              ),
              Text(
                displayChange.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 ${AppLocalizations.of(context)!.progressTrendTitle}',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Mini chart for waist
              _buildMiniChart(
                'Circonferenza Vita',
                'waist_cm',
                CleanTheme.primaryColor,
              ),
              const Divider(height: 32),
              _buildMiniChart(
                'Bicipite',
                'bicep_right_cm',
                CleanTheme.accentBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChart(String title, String field, Color color) {
    final values = _measurementsHistory
        .take(10)
        .map((m) => _parseNum((m as Map<String, dynamic>)[field]))
        .where((v) => v != null)
        .toList()
        .reversed
        .toList();

    if (values.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          AppLocalizations.of(context)!.progressAddMoreData,
          style: GoogleFonts.inter(color: CleanTheme.textTertiary),
        ),
      );
    }

    final maxVal = values.reduce((a, b) => a! > b! ? a : b)!;
    final minVal = values.reduce((a, b) => a! < b! ? a : b)!;
    final range = maxVal - minVal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            Text(
              '${values.last} cm',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values.asMap().entries.map((entry) {
              final value = entry.value!;
              final normalizedHeight = range > 0
                  ? ((value - minVal) / range * 40) + 20
                  : 40.0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: normalizedHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.3 + (entry.key / values.length * 0.7),
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBodySilhouetteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧍 ${AppLocalizations.of(context)!.progressBodyMapTitle}',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.progressBodyMapHint,
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: InteractiveBodySilhouette(
            measurements: _latestMeasurements,
            changes: _changes,
            onBodyPartTap: (partId) {
              debugPrint('Tapped body part: $partId');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🎯 ${AppLocalizations.of(context)!.progressGoalsTitle}',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddGoalDialog,
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppLocalizations.of(context)!.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_goals.isEmpty)
          _buildEmptyGoalsCard()
        else
          ..._goals.map((goal) => _buildGoalCard(goal as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildEmptyGoalsCard() {
    return CleanCard(
      padding: const EdgeInsets.all(24),
      onTap: _showAddGoalDialog,
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.progressSetGoal,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.progressGoalHint,
            style: GoogleFonts.inter(
              color: CleanTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final target = _parseNum(goal['target_value']) ?? 0;
    final current = _parseNum(goal['current_value']) ?? 0;
    final initial = _parseNum(goal['initial_value']) ?? current;
    final progress = (initial - current).abs() / (initial - target).abs();
    final isAchieved = progress >= 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAchieved
            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
            : CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAchieved ? CleanTheme.accentGreen : CleanTheme.borderPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal['name'] ?? 'Obiettivo',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              if (isAchieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🏆 Raggiunto!',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$current',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.primaryColor,
                ),
              ),
              Text(
                ' / $target cm',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: AlwaysStoppedAnimation(
                isAchieved ? CleanTheme.accentGreen : CleanTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    String? selectedMeasurement;
    final targetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎯 Nuovo Obiettivo',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Misura',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'waist_cm', child: Text('⭕ Vita')),
                DropdownMenuItem(
                  value: 'bicep_right_cm',
                  child: Text('💪 Bicipite'),
                ),
                DropdownMenuItem(value: 'chest_cm', child: Text('👕 Petto')),
                DropdownMenuItem(value: 'weight_kg', child: Text('⚖️ Peso')),
              ],
              onChanged: (value) => selectedMeasurement = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Obiettivo (cm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            CleanButton(
              text: 'Salva Obiettivo',
              onPressed: () {
                if (selectedMeasurement != null &&
                    targetController.text.isNotEmpty) {
                  _saveGoal(
                    selectedMeasurement!,
                    double.parse(targetController.text),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGoal(String measurement, double target) async {
    try {
      await _apiClient.dio.post(
        '/progress/goals',
        data: {'measurement_type': measurement, 'target_value': target},
      );
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Widget _buildAchievementsSection() {
    // Predefined achievements based on progress
    final List<Map<String, dynamic>> achievements = [
      {
        'icon': '📏',
        'title': 'Prima Misura',
        'description': 'Hai registrato la prima misurazione',
        'unlocked': _measurementsHistory.isNotEmpty,
      },
      {
        'icon': '🔥',
        'title': 'Costanza',
        'description': '4 settimane consecutive di misurazioni',
        'unlocked': _streak >= 4,
      },
      {
        'icon': '📉',
        'title': 'Vita Più Snella',
        'description': 'Hai ridotto la vita di 2+ cm',
        'unlocked': (_changes?['waist_cm'] as num? ?? 0) <= -2,
      },
      {
        'icon': '💪',
        'title': 'Braccia Potenti',
        'description': 'Hai aumentato il bicipite di 1+ cm',
        'unlocked': (_changes?['bicep_right_cm'] as num? ?? 0) >= 1,
      },
      {
        'icon': '🏆',
        'title': 'Trasformazione',
        'description': '12 settimane di tracciamento',
        'unlocked': _streak >= 12,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Traguardi',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              final unlocked = achievement['unlocked'] as bool;

              return Container(
                width: 115,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: unlocked
                      ? CleanTheme.accentYellow.withValues(alpha: 0.1)
                      : CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked
                        ? CleanTheme.accentYellow
                        : CleanTheme.borderSecondary,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      unlocked ? achievement['icon'] : '🔒',
                      style: TextStyle(
                        fontSize: 24, // Reduced font size
                        color: unlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement['title'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: unlocked
                            ? CleanTheme.textPrimary
                            : CleanTheme.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // Limit lines
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Removed extra spacer if present or simplified structure
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚡ Azioni Rapide',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.straighten,
                label: 'Nuova Misura',
                color: CleanTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BodyMeasurementsScreen(),
                  ),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.photo_camera,
                label: 'Foto Progresso',
                color: CleanTheme.accentBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressPhotosScreen(),
                  ),
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.compare,
                label: 'Confronta',
                color: CleanTheme.accentGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressComparisonScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGigiInsights() {
    String message =
        'Fantastico lavoro! Continua così per raggiungere i tuoi obiettivi.';
    GigiEmotion emotion = GigiEmotion.happy;

    if (_streak > 0) {
      if (_streak >= 4) {
        message =
            'Sei inarrestabile! $_streak settimane di fila sono un risultato incredibile. La tua costanza è la chiave per il successo.';
        emotion = GigiEmotion.celebrating;
      } else {
        message =
            'Ottima costanza! Hai mantenuto $_streak settimane di misurazioni. Questo mi aiuta a calibrare meglio il tuo piano.';
        emotion = GigiEmotion.motivational;
      }
    } else if (_measurementsHistory.isEmpty) {
      message =
          'Benvenuto nei progressi! Aggiungi la tua prima misura per aiutarmi a capire come sta reagendo il tuo corpo.';
      emotion = GigiEmotion.expert;
    }

    // Check for recent changes
    if (_changes != null && _changes!.isNotEmpty) {
      final weightChange = _parseNum(_changes!['weight_kg']);
      if (weightChange != null && weightChange < 0) {
        message =
            'Ho notato una diminuzione di peso: ottimo lavoro sulla definizione! Stai andando alla grande.';
        emotion = GigiEmotion.celebrating;
      }
    }

    return GigiCoachMessage(message: message, emotion: emotion);
  }
}
