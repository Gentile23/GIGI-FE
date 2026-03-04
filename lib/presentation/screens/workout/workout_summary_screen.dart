import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/clean_theme.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/workout/workout_share_card.dart';

/// Data class for workout summary statistics
class WorkoutSummaryData {
  final String workoutName;
  final Duration duration;
  final int completedExercises;
  final int totalExercises;
  final int estimatedCalories;
  final int completedSets;
  final List<String> muscleGroupsWorked;

  // Stats derivati dai set loggati
  final double totalKgLifted;
  final int totalReps;
  final double? avgRpe;

  WorkoutSummaryData({
    required this.workoutName,
    required this.duration,
    required this.completedExercises,
    required this.totalExercises,
    required this.estimatedCalories,
    required this.completedSets,
    required this.muscleGroupsWorked,
    this.totalKgLifted = 0,
    this.totalReps = 0,
    this.avgRpe,
  });

  double get completionPercentage =>
      totalExercises > 0 ? (completedExercises / totalExercises) * 100 : 0;

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedKg {
    if (totalKgLifted >= 1000) {
      return '${(totalKgLifted / 1000).toStringAsFixed(1)}t';
    }
    return totalKgLifted % 1 == 0
        ? '${totalKgLifted.toInt()} kg'
        : '${totalKgLifted.toStringAsFixed(1)} kg';
  }
}

/// Full-screen workout summary shown after finishing a session
class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData summaryData;

  const WorkoutSummaryScreen({super.key, required this.summaryData});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isGeneratingImage = false;
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Play confetti if they completed at least one exercise
    if (widget.summaryData.completedExercises > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.summaryData;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CleanTheme.primaryColor.withValues(alpha: 0.15),
                  CleanTheme.backgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Trophy/Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [CleanTheme.steelDark, CleanTheme.primaryColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 50,
                      color: CleanTheme.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    data.completedExercises > 0
                        ? l10n.workoutCompletedTitle
                        : 'Sessione Terminata',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.workoutName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Main Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          value: data.formattedDuration,
                          label: l10n.durationLabel,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '${data.estimatedCalories}',
                          label: l10n.caloriesLabel,
                          color: CleanTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.fitness_center_rounded,
                          value:
                              '${data.completedExercises}/${data.totalExercises}',
                          label: l10n.exercisesLabel,
                          color: CleanTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.repeat_rounded,
                          value: '${data.completedSets}',
                          label: l10n.totalSetsLabel,
                          color: CleanTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dati sessione reali (kg, reps, RPE)
                  if (data.totalKgLifted > 0 || data.totalReps > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CleanTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: CleanTheme.accentGold.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CleanTheme.accentGold.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: CleanTheme.accentGold.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bar_chart_rounded,
                                  size: 18,
                                  color: CleanTheme.accentGold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Dati Sessione',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (data.totalKgLifted > 0)
                                Expanded(
                                  child: _buildDetailStat(
                                    emoji: '🏋️',
                                    value: data.formattedKg,
                                    label: 'KG Sollevati',
                                    color: CleanTheme.accentGold,
                                  ),
                                ),
                              if (data.totalKgLifted > 0 && data.totalReps > 0)
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: CleanTheme.borderPrimary,
                                ),
                              if (data.totalReps > 0)
                                Expanded(
                                  child: _buildDetailStat(
                                    emoji: '🔁',
                                    value: '${data.totalReps}',
                                    label: 'Reps Totali',
                                    color: CleanTheme.accentBlue,
                                  ),
                                ),
                              if (data.avgRpe != null) ...[
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: CleanTheme.borderPrimary,
                                ),
                                Expanded(
                                  child: _buildDetailStat(
                                    emoji: '🎯',
                                    value: data.avgRpe!.toStringAsFixed(1),
                                    label: 'RPE Medio',
                                    color: CleanTheme.accentOrange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (data.completedSets > 0) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildDetailStat(
                              emoji: '📊',
                              value:
                                  data.totalKgLifted > 0 &&
                                      data.completedSets > 0
                                  ? '${(data.totalKgLifted / data.completedSets).toStringAsFixed(1)} kg'
                                  : '-',
                              label: 'Media kg/serie',
                              color: CleanTheme.primaryColor,
                              compact: false,
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Completion Progress
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completamento',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${data.completionPercentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.completionPercentage / 100,
                            backgroundColor: CleanTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              data.completionPercentage >= 100
                                  ? CleanTheme.accentGreen
                                  : CleanTheme.primaryColor,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Muscle Groups Worked
                  if (data.muscleGroupsWorked.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CleanTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CleanTheme.borderPrimary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muscoli Allenati',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.muscleGroupsWorked.map((muscle) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: CleanTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  muscle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: CleanTheme.primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Motivational Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.steelMid.withValues(alpha: 0.5),
                          CleanTheme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('💪', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          _getMotivationalMessage(data),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: CleanTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Share Card CTA
                  _buildShareCTA(),
                  const SizedBox(height: 20),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CleanTheme.primaryColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        l10n.close, // Matches 'Chiudi'
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textOnPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Hidden RepaintBoundary for Image Generation
                  Offstage(
                    child: RepaintBoundary(
                      key: _shareCardKey,
                      child: SizedBox(
                        width: 1080, // High res for sharing
                        child: WorkoutShareCard(
                          summaryData: data,
                          photo: _selectedPhoto,
                          userName: Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).user?.name,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                CleanTheme.primaryColor,
                CleanTheme.accentGreen,
                CleanTheme.accentOrange,
                CleanTheme.accentPurple,
                CleanTheme.accentBlue,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat({
    required String emoji,
    required String value,
    required String label,
    required Color color,
    bool compact = true,
  }) {
    if (compact) {
      return Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(WorkoutSummaryData data) {
    if (data.completionPercentage >= 100) {
      return 'Allenamento completato al 100%! Sei una macchina! 🔥';
    } else if (data.completionPercentage >= 75) {
      return 'Ottimo lavoro! Hai dato il massimo oggi!';
    } else if (data.completionPercentage >= 50) {
      return 'Buon allenamento! Ogni passo conta verso i tuoi obiettivi.';
    } else if (data.completedExercises > 0) {
      return 'Hai iniziato e questo è già un successo! Continua così!';
    } else {
      return 'Preparazione completata. La prossima volta spacchi tutto! 💪';
    }
  }

  Widget _buildShareCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'MOSTRA IL TUO VALORE',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: CleanTheme.accentOrange,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Condividi la tua vittoria con la community',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildShareButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'FOTO ORA',
                  onTap: () => _handleShare(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareButton(
                  icon: Icons.photo_library_rounded,
                  label: 'GALLERY',
                  onTap: () => _handleShare(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedPhoto = File(image.path);
      });

      // Give a tiny bit of time for the Offstage RepaintBoundary to update with the new photo
      await Future.delayed(const Duration(milliseconds: 300));

      await _generateAndShareImage();
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la selezione della foto'),
          ),
        );
      }
    }
  }

  Future<void> _generateAndShareImage() async {
    if (_isGeneratingImage) return;

    setState(() {
      _isGeneratingImage = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.accentOrange),
      ),
    );

    try {
      RenderRepaintBoundary boundary =
          _shareCardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Wait for it to be actually rendered
      ui.Image image = await boundary.toImage(
        pixelRatio: 2.0,
      ); // 2x for better quality
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/gigi_workout_share.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context); // Pop loading

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Ho appena spaccato con GiGi! 🔥 #GiGiWorkout #OgniSetConta',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating image: $e');
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la generazione dell\'immagine'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
        });
      }
    }
  }
}
