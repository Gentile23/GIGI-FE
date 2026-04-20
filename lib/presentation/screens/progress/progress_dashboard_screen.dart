import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/progress/interactive_body_silhouette.dart';
import '../../../data/services/api_client.dart';
import '../../../core/constants/gigi_guidance_content.dart';
import '../../../core/services/workout_refresh_notifier.dart';
import 'body_measurements_screen.dart';
import '../../widgets/progress/body_part_detail_sheet.dart';
import '../history/stats_screen.dart'; // Add import for StatsScreen

import 'package:provider/provider.dart';
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
  late final WorkoutRefreshNotifier _workoutRefreshNotifier;

  // Data
  Map<String, dynamic>? _latestMeasurements;
  Map<String, dynamic>? _changes;
  Map<String, dynamic>? _overviewStats;

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _workoutRefreshNotifier = Provider.of<WorkoutRefreshNotifier>(
      context,
      listen: false,
    );
    _workoutRefreshNotifier.addListener(_handleWorkoutRefresh);
    _loadData();
  }

  @override
  void dispose() {
    _workoutRefreshNotifier.removeListener(_handleWorkoutRefresh);
    super.dispose();
  }

  void _handleWorkoutRefresh() {
    debugPrint(
      'ProgressDashboardScreen: received workout refresh v${_workoutRefreshNotifier.version}',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final overviewResponse = await _apiClient.dio.get('/stats/overview');

      // Fetch measurements data independently from workout stats
      final measurementsResponse = await _apiClient.dio.get(
        '/progress/measurements',
      );

      if (!mounted) return;

      final measurementsData = measurementsResponse.data;

      setState(() {
        _overviewStats = overviewResponse.data['stats'] is Map<String, dynamic>
            ? overviewResponse.data['stats']
            : null;
        _latestMeasurements = measurementsData['latest'] is Map<String, dynamic>
            ? measurementsData['latest']
            : null;
        _changes = measurementsData['changes'] is Map<String, dynamic>
            ? measurementsData['changes']
            : {};
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _overviewStats = null;
          _latestMeasurements = null;
          _changes = {};
        });
      }
    }
  }

  Widget _buildWorkoutStatsSection() {
    final overviewStats = _overviewStats;
    final totalWorkouts = _asInt(overviewStats?['total_workouts']);
    final totalSets = _asInt(overviewStats?['total_sets']);
    final totalWeight = _asDouble(overviewStats?['total_volume_kg']);
    final currentStreak = _asInt(overviewStats?['current_streak']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.progressStatsTitle,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildWowStatCard(
              label: AppLocalizations.of(context)!.progressWorkouts,
              value: '$totalWorkouts',
              icon: Icons.fitness_center_rounded,
              color: CleanTheme.accentBlue,
              unit: 'sessioni',
            ),
            _buildWowStatCard(
              label: AppLocalizations.of(context)!.progressTotalSets,
              value: '$totalSets',
              icon: Icons.layers_rounded,
              color: CleanTheme.accentOrange,
              unit: 'serie completate',
            ),
            _buildWowStatCard(
              label: 'Volume Totale',
              value: totalWeight >= 1000 
                ? (totalWeight / 1000).toStringAsFixed(1) 
                : totalWeight.toStringAsFixed(0),
              icon: Icons.monitor_weight_rounded,
              color: CleanTheme.accentGreen,
              unit: totalWeight >= 1000 ? 'tonnellate' : 'kg sollevati',
            ),
            _buildWowStatCard(
              label: 'Costanza',
              value: '$currentStreak',
              icon: Icons.local_fire_department_rounded,
              color: CleanTheme.accentRed,
              unit: 'giorni consecutivi',
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () {
              HapticService.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: Text(
              'Vedi di più',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: CleanTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CleanTheme.primaryColor.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWowStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CleanTheme.borderPrimary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 32),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Workout History Stats (Moved to Top)
                    _buildWorkoutStatsSection(),
                    const SizedBox(height: 32),

                    // Gigi AI Guide
                    _buildGigiInsights(),
                    const SizedBox(height: 32),

                    // Body Silhouette
                    _buildBodySilhouetteSection(),
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBodySilhouetteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.progressBodyMapTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.progressBodyMapHint,
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: InteractiveBodySilhouette(
            measurements: _latestMeasurements,
            changes: _changes,
            onBodyPartTap: (partId) {
              _showBodyPartDetail(partId);
            },
          ),
        ),
      ],
    );
  }

  void _showBodyPartDetail(String partId) {
    HapticService.mediumTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BodyPartDetailSheet(
        partId: partId,
        currentValue: _latestMeasurements?[partId],
        change: _changes?[partId],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BodyMeasurementsScreen()),
        ).then((_) => _loadData());
      },
      child: LiquidSteelContainer(
        borderRadius: 16,
        enableShine: true,
        border: Border.all(
          color: CleanTheme.textOnPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(
                  Icons.straighten,
                  color: CleanTheme.textOnPrimary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nuova Misura',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textOnPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Traccia i tuoi progressi corporei',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textOnPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: CleanTheme.textOnPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGigiInsights() {
    return Center(
      child: GigiCoachMessage(
        messageId: 'progress.dashboard.overview',
        title: 'Come leggere i progressi',
        message: GigiGuidanceContent.progressDashboard(),
        emotion: GigiEmotion.expert,
      ),
    );
  }
}
