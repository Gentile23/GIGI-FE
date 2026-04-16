import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:gigi/l10n/app_localizations.dart';

import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/workout/workout_share_card.dart';
import '../../../providers/auth_provider.dart';

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
  final Color color;

  const _SummaryMetric(this.label, this.value, this.icon, this.color);
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
  final ImagePicker _picker = ImagePicker();
  late final ConfettiController _confettiController;

  bool _isGeneratingImage = false;
  Uint8List? _selectedPhotoBytes;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.summaryData.completedExercises > 0) {
        _confettiController.play();
      }
    });
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
      backgroundColor: CleanTheme.chromeSubtle,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -40,
            child: _buildBackdropGlow(
              size: 240,
              color: CleanTheme.accentGold.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 120,
            left: -80,
            child: _buildBackdropGlow(
              size: 220,
              color: CleanTheme.chromeGray.withValues(alpha: 0.12),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildHeroCard(data),
                  const SizedBox(height: 16),
                  _buildSectionTitle(
                    eyebrow: 'Riepilogo sessione',
                    title: 'Numeri chiave',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.02,
                    children: [
                      _buildMetricCard(
                        icon: Icons.timer_outlined,
                        label: l10n.durationLabel,
                        value: data.formattedDuration,
                        color: CleanTheme.accentBlue,
                      ),
                      _buildMetricCard(
                        icon: Icons.fitness_center_rounded,
                        label: l10n.exercisesLabel,
                        value:
                            '${data.completedExercises}/${data.totalExercises}',
                        color: CleanTheme.accentGreen,
                      ),
                      _buildMetricCard(
                        icon: Icons.repeat_rounded,
                        label: l10n.totalSetsLabel,
                        value: '${data.completedSets}',
                        color: CleanTheme.accentOrange,
                      ),
                      _buildMetricCard(
                        icon: Icons.local_fire_department_outlined,
                        label: l10n.caloriesLabel,
                        value: '${data.estimatedCalories}',
                        color: CleanTheme.accentRed,
                      ),
                    ],
                  ),
                  if (data.totalKgLifted > 0 ||
                      data.totalReps > 0 ||
                      data.avgRpe != null) ...[
                    const SizedBox(height: 16),
                    _buildPerformanceCard(data),
                  ],
                  if (data.muscleGroupsWorked.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMuscleCard(data),
                  ],
                  const SizedBox(height: 16),
                  _buildShareCTA(),
                  const SizedBox(height: 18),
                  _buildCloseButton(l10n),
                ],
              ),
            ),
          ),
          _buildConfettiLayer(Alignment.topCenter, 0),
          _buildConfettiLayer(Alignment.topLeft, math.pi / 14),
          _buildConfettiLayer(Alignment.topRight, math.pi - (math.pi / 14)),
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
                        photoBytes: _selectedPhotoBytes,
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
            boxShadow: CleanTheme.cardShadow,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allenamento completato',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Text(
                'Riepilogo finale in stile coach',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(WorkoutSummaryData data) {
    final progress = (data.completionPercentage / 100).clamp(0.0, 1.0);

    return LiquidSteelContainer(
      borderRadius: 28,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: CleanTheme.accentGold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Workout complete',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.88),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.workoutName,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getSummaryMessage(data),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    value: '${data.completionPercentage.toStringAsFixed(0)}%',
                    label: 'Completamento',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHeroStat(
                    value: data.formattedKg,
                    label: 'Volume totale',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  CleanTheme.accentGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String eyebrow, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: CleanTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
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
        _SummaryMetric(
          'Volume',
          data.formattedKg,
          Icons.scale_rounded,
          CleanTheme.accentBlue,
        ),
      if (data.totalReps > 0)
        _SummaryMetric(
          'Ripetizioni',
          '${data.totalReps}',
          Icons.repeat_rounded,
          CleanTheme.accentOrange,
        ),
      if (data.avgRpe != null)
        _SummaryMetric(
          'RPE medio',
          data.avgRpe!.toStringAsFixed(1),
          Icons.speed_rounded,
          CleanTheme.accentGold,
        ),
      if (averageKg != null)
        _SummaryMetric(
          'Media kg/serie',
          averageKg,
          Icons.query_stats_rounded,
          CleanTheme.accentGreen,
        ),
    ];

    return _buildSurfaceCard(
      eyebrow: 'Performance',
      title: 'Dettagli del lavoro svolto',
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildMetricRow(items[i]),
            if (i != items.length - 1)
              Divider(
                height: 22,
                color: CleanTheme.borderSecondary.withValues(alpha: 0.8),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuscleCard(WorkoutSummaryData data) {
    return _buildSurfaceCard(
      eyebrow: 'Focus muscolare',
      title: 'Muscoli allenati',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: data.muscleGroupsWorked.map((muscle) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: CleanTheme.chromeSubtle.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              muscle,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSurfaceCard({
    required String eyebrow,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
        boxShadow: CleanTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow(_SummaryMetric item) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          item.value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _getSummaryMessage(WorkoutSummaryData data) {
    if (data.completionPercentage >= 100) {
      return '';
    }
    if (data.completedExercises > 0) {
      return '';
    }
    return '';
  }

  Widget _buildShareCTA() {
    return _buildSurfaceCard(
      eyebrow: 'Share',
      title: 'Condividi il riepilogo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crea una card pulita con foto e statistiche reali della sessione.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildShareButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Foto ora',
                  onTap: () => _handleShare(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galleria',
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CleanTheme.steelMid, CleanTheme.steelDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: CleanTheme.textOnDark, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textOnDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: CleanTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildBackdropGlow({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size / 2, spreadRadius: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildConfettiLayer(Alignment alignment, double blastDirection) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.directional,
        blastDirection: blastDirection == 0 ? math.pi / 2 : blastDirection,
        emissionFrequency: 0.055,
        numberOfParticles: 16,
        maxBlastForce: 10,
        minBlastForce: 3,
        gravity: 0.24,
        shouldLoop: false,
        colors: const [
          Color(0xFFFF6B6B),
          Color(0xFFFFD166),
          Color(0xFF06D6A0),
          Color(0xFF118AB2),
          Color(0xFF9B5DE5),
          Color(0xFFFF8FAB),
        ],
        createParticlePath: _buildConfettiParticlePath,
      ),
    );
  }

  Path _buildConfettiParticlePath(Size size) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.65),
        const Radius.circular(3),
      ),
    );
    return path;
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
      if (!mounted) return;

      final selectedPhotoBytes = await image.readAsBytes();
      if (!mounted) return;

      await precacheImage(MemoryImage(selectedPhotoBytes), context);

      setState(() {
        _selectedPhotoBytes = selectedPhotoBytes;
      });

      await _waitForShareCardToPaint();

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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.accentOrange),
      ),
    );

    try {
      await _waitForShareCardToPaint();

      final boundaryContext = _shareCardKey.currentContext;
      final renderObject = boundaryContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Share card non pronta');
      }

      await _waitForShareCardToPaint();

      final ui.Image image = await renderObject.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/gigi_workout_share.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context);

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
        Navigator.pop(context);
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

  Future<void> _waitForShareCardToPaint() async {
    RenderRepaintBoundary? boundary;

    for (var attempt = 0; attempt < 20; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 16));

      final boundaryContext = _shareCardKey.currentContext;
      final renderObject = boundaryContext?.findRenderObject();

      if (renderObject is RenderRepaintBoundary) {
        boundary = renderObject;
        if (!renderObject.debugNeedsLayout && !renderObject.debugNeedsPaint) {
          return;
        }
      }
    }

    if (boundary == null) {
      throw StateError('Share card non pronta');
    }

    throw StateError('Share card non ha completato il paint');
  }
}
