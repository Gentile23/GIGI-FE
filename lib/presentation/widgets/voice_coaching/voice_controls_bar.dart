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
        // Only show when guided execution is active!
        final isVisible = controller.isGuidedExecutionPlaying;

        // Check if actually speaking/playing from TTS service perspective would be better,
        // but controller state should suffice for visibility.
        // We might want to query ttsService.isSpeaking for the play/pause icon state.

        // Note: We can't easily access ttsService directly here unless exposed.
        // But we can assume if isGuidedExecutionPlaying is true, we started it.
        // We risk UI state desync if we rely solely on variables without polling or streams.
        // However, SynchronizedVoiceController notifies listeners on state changes.

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

                  // Play/Pause (We need to Toggle)
                  // Since we don't have isPaused state explicitly exposed as public getter in controller (only private or via service),
                  // we might need to add `get isPaused` to controller or just show Pause generally when visible.
                  // For now, let's assume if it's visible, it's playing, or we provide both.
                  IconButton(
                    icon: const Icon(
                      Icons.pause_rounded,
                      color: CleanTheme.accentOrange,
                      size: 28,
                    ),
                    onPressed: () => controller.pauseAudio(),
                    tooltip: AppLocalizations.of(context)!.pause,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: CleanTheme.accentGreen,
                      size: 28,
                    ),
                    onPressed: () => controller.resumeAudio(),
                    tooltip: AppLocalizations.of(context)!.resume,
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
