import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  double get completionPercentage => totalExercises > 0
      ? ((completedExercises / totalExercises) * 100).clamp(0, 100).toDouble()
      : 0;

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

class _SummaryMetric {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric(this.label, this.value, this.icon);
}

/// Full-screen workout summary shown after finishing a session
class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData summaryData;

  const WorkoutSummaryScreen({super.key, required this.summaryData});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isGeneratingImage = false;
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final data = widget.summaryData;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: CleanTheme.textOnDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.completedExercises > 0
                                  ? 'Allenamento completato'
                                  : 'Sessione terminata',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.workoutName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CleanTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildCompletionCard(data),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _buildMetricCard(
                        icon: Icons.timer_outlined,
                        label: l10n.durationLabel,
                        value: data.formattedDuration,
                      ),
                      _buildMetricCard(
                        icon: Icons.fitness_center_rounded,
                        label: l10n.exercisesLabel,
                        value:
                            '${data.completedExercises}/${data.totalExercises}',
                      ),
                      _buildMetricCard(
                        icon: Icons.repeat_rounded,
                        label: l10n.totalSetsLabel,
                        value: '${data.completedSets}',
                      ),
                      _buildMetricCard(
                        icon: Icons.local_fire_department_outlined,
                        label: l10n.caloriesLabel,
                        value: '${data.estimatedCalories}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (data.totalKgLifted > 0 ||
                      data.totalReps > 0 ||
                      data.avgRpe != null)
                    _buildPerformanceCard(data),

                  if (data.muscleGroupsWorked.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMuscleCard(data),
                  ],

                  const SizedBox(height: 20),
                  _buildShareCTA(),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CleanTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n.close,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CleanTheme.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.001,
                child: Center(
                  child: RepaintBoundary(
                    key: _shareCardKey,
                    child: SizedBox(
                      width: 360,
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(WorkoutSummaryData data) {
    final progress = data.completionPercentage / 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CleanTheme.borderSecondary),
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
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Text(
                '${data.completionPercentage.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CleanTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getSummaryMessage(data),
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.35,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: CleanTheme.textPrimary, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(WorkoutSummaryData data) {
    final averageKg = data.totalKgLifted > 0 && data.completedSets > 0
        ? '${(data.totalKgLifted / data.completedSets).toStringAsFixed(1)} kg'
        : null;

    final items = <_SummaryMetric>[
      if (data.totalKgLifted > 0)
        _SummaryMetric('Volume', data.formattedKg, Icons.scale_rounded),
      if (data.totalReps > 0)
        _SummaryMetric('Ripetizioni', '${data.totalReps}', Icons.repeat),
      if (data.avgRpe != null)
        _SummaryMetric(
          'RPE medio',
          data.avgRpe!.toStringAsFixed(1),
          Icons.speed_rounded,
        ),
      if (averageKg != null)
        _SummaryMetric('Media kg/serie', averageKg, Icons.query_stats_rounded),
    ];

    return _buildInfoCard(
      title: 'Performance',
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildMetricRow(items[i]),
          if (i != items.length - 1) const Divider(height: 18),
        ],
      ],
    );
  }

  Widget _buildMuscleCard(WorkoutSummaryData data) {
    return _buildInfoCard(
      title: 'Muscoli allenati',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.muscleGroupsWorked.map((muscle) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CleanTheme.chromeSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                muscle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow(_SummaryMetric item) {
    return Row(
      children: [
        Icon(item.icon, color: CleanTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ),
        Text(
          item.value,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getSummaryMessage(WorkoutSummaryData data) {
    if (data.completionPercentage >= 100) {
      return 'Hai completato tutti gli esercizi previsti.';
    }
    if (data.completedExercises > 0) {
      return 'Sessione registrata con gli esercizi completati.';
    }
    return 'Sessione chiusa senza esercizi completati.';
  }

  Widget _buildShareCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condividi riepilogo',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea una card pulita con i dati reali della sessione.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: CleanTheme.textOnDark, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textOnDark,
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

      await WidgetsBinding.instance.endOfFrame;

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
      await WidgetsBinding.instance.endOfFrame;

      final boundaryContext = _shareCardKey.currentContext;
      final renderObject = boundaryContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Share card non pronta');
      }

      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }

      ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
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
