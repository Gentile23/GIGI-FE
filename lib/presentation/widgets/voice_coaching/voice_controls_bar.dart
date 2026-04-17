import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/synchronized_voice_controller.dart';

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
        final isVisible = controller.canStop;
        final showPause = controller.canPause;
        final showResume = controller.canResume;

        return AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !isVisible,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CleanTheme.steelDark.withValues(alpha: 0.95),
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
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        controller.seekAudio(const Duration(seconds: -10)),
                    tooltip: '-10s',
                  ),

                  IconButton(
                    icon: Icon(
                      showResume
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: showResume ? CleanTheme.accentGreen : Colors.white,
                      size: 28,
                    ),
                    onPressed: showResume
                        ? () => controller.resumeAudio()
                        : (showPause ? () => controller.pauseAudio() : null),
                    tooltip: showResume
                        ? AppLocalizations.of(context)!.resume
                        : AppLocalizations.of(context)!.pause,
                  ),

                  // Forward 10s
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        controller.seekAudio(const Duration(seconds: 10)),
                    tooltip: '+10s',
                  ),

                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: Colors.white24),
                  const SizedBox(width: 8),

                  // Stop / Close
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: CleanTheme.accentRed,
                    ),
                    onPressed: () => controller.stopGuidedExecution(),
                    tooltip: AppLocalizations.of(context)!.close,
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
