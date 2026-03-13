import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/progress/interactive_body_silhouette.dart';
import '../../../data/services/api_client.dart';
import 'body_measurements_screen.dart';

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


      if (mounted) {
        final measurementsData = measurementsResponse.data;

        setState(() {
          _latestMeasurements =
              measurementsData['latest'] is Map<String, dynamic>
              ? measurementsData['latest']
              : null;
          _changes = measurementsData['changes'] is Map<String, dynamic>
              ? measurementsData['changes']
              : {};
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context)!.progressStatsTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
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
                      '$_totalWorkouts',
                      AppLocalizations.of(context)!.progressWorkouts,
                    ),
                  ),
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '$_totalSeries',
                      AppLocalizations.of(context)!.progressTotalSets,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildWorkoutStatItem(
                      '$_totalCalories',
                      AppLocalizations.of(context)!.progressCalories,
                    ),
                  ),
                  Expanded(
                    child: _buildWorkoutStatItem(
                      hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                      AppLocalizations.of(context)!.progressTotalTime,
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
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CleanTheme.primaryColor,
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
              debugPrint('Tapped body part: $partId');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BodyMeasurementsScreen(),
          ),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.straighten,
                  color: CleanTheme.textOnPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuova Misura',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textOnPrimary,
                      ),
                    ),
                    Text(
                      'Traccia i tuoi progressi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textOnPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: CleanTheme.textOnPrimary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildGigiInsights() {
    return const Center(
      child: GigiCoachMessage(
        message:
            'Monitorare le tue misure mi permette di capire esattamente come il tuo corpo sta reagendo agli allenamenti e alla dieta. In questo modo posso calibrare perfettamente i tuoi piani futuri!',
        emotion: GigiEmotion.expert,
      ),
    );
  }
}
