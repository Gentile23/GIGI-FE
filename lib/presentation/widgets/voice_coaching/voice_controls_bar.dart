import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/synchronized_voice_controller.dart';
import 'voice_coaching_toggle.dart';

/// Floating audio controls bar for Voice Coaching
/// Appears at top-center when Voice Coaching is active
class VoiceControlsBar extends StatelessWidget {
  final SynchronizedVoiceController controller;

  const VoiceControlsBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isEnabled = controller.isEnabled;
        final isSpeaking =
            controller.phase == VoiceCoachingPhase.explaining ||
            controller.phase == VoiceCoachingPhase.activated ||
            controller.phase == VoiceCoachingPhase.postSet ||
            controller.isGuidedExecutionPlaying;

        // Animated visibility
        return AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !isEnabled,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1E1E2C,
                ).withValues(alpha: 0.9), // Dark glass
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Status Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSpeaking
                          ? CleanTheme.accentGreen
                          : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSpeaking
                                      ? CleanTheme.accentGreen
                                      : Colors.orange)
                                  .withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Status Text
                  Text(
                    isSpeaking ? 'Gigi parla...' : 'In ascolto',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Divider
                  Container(
                    width: 1,
                    height: 16,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),

                  const SizedBox(width: 8),

                  // 3. Controls

                  // Stop Button (only if speaking)
                  if (isSpeaking) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.stop_rounded,
                        color: CleanTheme.accentRed,
                        size: 20,
                      ),
                      onPressed: () => controller
                          .stopGuidedExecution(), // Or a generic stopSpeech if available
                      tooltip: 'Stop Audio',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],

                  // Settings Button
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    onPressed: () {
                      VoiceCoachingSettingsSheet.show(context, controller);
                    },
                    tooltip: 'Impostazioni',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
