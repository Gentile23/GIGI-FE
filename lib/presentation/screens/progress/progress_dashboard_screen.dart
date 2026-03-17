import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/progress/interactive_body_silhouette.dart';
import '../../../data/services/api_client.dart';
import 'body_measurements_screen.dart';
import '../../widgets/progress/body_part_detail_sheet.dart';

import 'package:provider/provider.dart';
import '../../../providers/gamification_provider.dart';
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

        // Load workout history stats from provider
        Provider.of<GamificationProvider>(context, listen: false).loadStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }






  Widget _buildWorkoutStatsSection() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        final totalWorkouts = stats?.totalWorkouts ?? 0;
        final totalSets = stats?.totalSetsCompleted ?? 0;
        final totalMinutes = stats?.totalMinutesTrained ?? 0;
        final totalWeight = stats?.totalWeightLifted ?? 0;

        final hours = totalMinutes ~/ 60;
        final mins = totalMinutes % 60;
        final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

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
                          '$totalWorkouts',
                          AppLocalizations.of(context)!.progressWorkouts,
                          Icons.fitness_center_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildWorkoutStatItem(
                          '$totalSets',
                          AppLocalizations.of(context)!.progressTotalSets,
                          Icons.layers_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildWorkoutStatItem(
                          '${totalWeight.toStringAsFixed(0)}kg',
                          'Peso Totale',
                          Icons.monitor_weight_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildWorkoutStatItem(
                          timeStr,
                          AppLocalizations.of(context)!.progressTotalTime,
                          Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutStatItem(
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderSecondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: CleanTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: CleanTheme.textOnPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CleanTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
            'Tocca i diversi muscoli sulla sagoma qui sotto per vedere lo storico dettagliato e i grafici dei tuoi progressi. Monitorare le tue misure mi permette di calibrare perfettamente i tuoi piani futuri!',
        emotion: GigiEmotion.expert,
      ),
    );
  }
}
