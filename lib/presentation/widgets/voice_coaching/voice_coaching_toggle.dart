import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/synchronized_voice_controller.dart';

/// Voice Coaching toggle button with animated audio waves
/// Positioned in top-right of workout screen
class VoiceCoachingToggle extends StatefulWidget {
  final SynchronizedVoiceController controller;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // For settings

  const VoiceCoachingToggle({
    super.key,
    required this.controller,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<VoiceCoachingToggle> createState() => _VoiceCoachingToggleState();
}

class _VoiceCoachingToggleState extends State<VoiceCoachingToggle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for active state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    widget.controller.addListener(_updateAnimations);
    _updateAnimations();
  }

  void _updateAnimations() {
    if (widget.controller.isEnabled) {
      _pulseController.repeat(reverse: true);
      if (widget.controller.phase == VoiceCoachingPhase.explaining ||
          widget.controller.phase == VoiceCoachingPhase.activated) {
        _waveController.repeat();
      } else {
        _waveController.stop();
        _waveController.value = 0;
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
      _waveController.stop();
      _waveController.value = 0;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateAnimations);
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.controller.isEnabled;
    final isMuted = widget.controller.isMuted;
    final isSpeaking =
        widget.controller.phase == VoiceCoachingPhase.explaining ||
        widget.controller.phase == VoiceCoachingPhase.activated ||
        widget.controller.phase == VoiceCoachingPhase.postSet ||
        widget.controller.isGuidedExecutionPlaying;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isEnabled ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CleanTheme.steelDark, CleanTheme.primaryColor],
                      )
                    : null,
                color: isEnabled ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(100),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Audio waves (when speaking)
                      if (isSpeaking && isEnabled)
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(24, 24),
                              painter: AudioWavePainter(
                                progress: _waveController.value,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            );
                          },
                        ),
                      // Main icon
                      Icon(
                        isMuted
                            ? Icons.mic_off_rounded
                            : isEnabled
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        color: isEnabled
                            ? Colors.white
                            : CleanTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gigi AI',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? Colors.white
                          : CleanTheme.textSecondary,
                    ),
                  ),
                  if (isEnabled) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for audio wave animation
class AudioWavePainter extends CustomPainter {
  final double progress;
  final Color color;

  AudioWavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw 3 expanding circular waves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + i * 0.33) % 1.0;
      final radius = 10 + (waveProgress * 14);
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(AudioWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Voice coaching settings bottom sheet
class VoiceCoachingSettingsSheet extends StatelessWidget {
  final SynchronizedVoiceController controller;

  const VoiceCoachingSettingsSheet({super.key, required this.controller});

  static void show(
    BuildContext context,
    SynchronizedVoiceController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VoiceCoachingSettingsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CleanTheme.steelDark, CleanTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Voice Coaching',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Mute toggle
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return _buildToggleRow(
                icon: controller.isMuted ? Icons.volume_off : Icons.volume_up,
                title: controller.isMuted
                    ? 'Audio disattivato'
                    : 'Audio attivo',
                subtitle:
                    'Tocca per ${controller.isMuted ? 'attivare' : 'disattivare'}',
                isActive: !controller.isMuted,
                onTap: () => controller.toggleMute(),
              );
            },
          ),
          const SizedBox(height: 16),

          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.volume_mute,
                        size: 20,
                        color: CleanTheme.textTertiary,
                      ),
                      Expanded(
                        child: Slider(
                          value: controller.volume,
                          onChanged: (v) => controller.setVolume(v),
                          activeColor: CleanTheme.primaryColor,
                          inactiveColor: CleanTheme.borderSecondary,
                        ),
                      ),
                      const Icon(
                        Icons.volume_up,
                        size: 20,
                        color: CleanTheme.textTertiary,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Minimal mode toggle
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return _buildToggleRow(
                icon: controller.minimalMode
                    ? Icons.notifications_off_outlined
                    : Icons.notifications_active_outlined,
                title: AppLocalizations.of(context)!.discreteMode,
                subtitle: controller.minimalMode
                    ? 'Feedback solo su prima e ultima serie'
                    : 'Feedback su ogni serie completata',
                isActive: controller.minimalMode,
                onTap: () => controller.setMinimalMode(!controller.minimalMode),
              );
            },
          ),
          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: CleanTheme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Usa "Esegui con Gigi" su ogni esercizio per una guida passo-passo di 2 ripetizioni perfette con posizionamento e consigli.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          SafeArea(child: Container()),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? CleanTheme.primaryColor.withValues(alpha: 0.08)
              : CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? CleanTheme.primaryColor.withValues(alpha: 0.3)
                : CleanTheme.borderSecondary,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? CleanTheme.primaryColor.withValues(alpha: 0.15)
                    : CleanTheme.borderSecondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive
                    ? CleanTheme.primaryColor
                    : CleanTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: (_) => onTap(),
              activeTrackColor: CleanTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
