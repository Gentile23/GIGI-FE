import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/exercise_intro_model.dart';
import '../clean_widgets.dart';

/// Mode Selection Sheet
///
/// Bottom sheet that appears before an exercise to let the user choose:
/// - Voice Mode: Full voice coaching with per-rep cues
/// - Music Mode: User's music + minimal Gigi interruptions
class ModeSelectionSheet extends StatefulWidget {
  final String exerciseName;
  final ExerciseIntroScript? intro;
  final CoachingMode currentMode;
  final bool rememberChoice;
  final Function(CoachingMode mode, bool remember) onModeSelected;
  final VoidCallback? onSkipIntro;

  const ModeSelectionSheet({
    super.key,
    required this.exerciseName,
    this.intro,
    this.currentMode = CoachingMode.voice,
    this.rememberChoice = false,
    required this.onModeSelected,
    this.onSkipIntro,
  });

  /// Show the mode selection sheet
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    ExerciseIntroScript? intro,
    CoachingMode currentMode = CoachingMode.voice,
    bool rememberChoice = false,
    required Function(CoachingMode mode, bool remember) onModeSelected,
    VoidCallback? onSkipIntro,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModeSelectionSheet(
        exerciseName: exerciseName,
        intro: intro,
        currentMode: currentMode,
        rememberChoice: rememberChoice,
        onModeSelected: onModeSelected,
        onSkipIntro: onSkipIntro,
      ),
    );
  }

  @override
  State<ModeSelectionSheet> createState() => _ModeSelectionSheetState();
}

class _ModeSelectionSheetState extends State<ModeSelectionSheet> {
  late CoachingMode _selectedMode;
  late bool _rememberChoice;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
    _rememberChoice = widget.rememberChoice;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CleanTheme.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  const Text('🏋️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Intro preview (if available)
              if (widget.intro != null) ...[
                CleanCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            color: CleanTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gigi ti spiega...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.intro!.greeting,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: CleanTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (widget.intro!.keyPoints.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.intro!.keyPoints,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.4,
                            color: CleanTheme.textTertiary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Mode selection title
              Text(
                'Scegli come vuoi allenarti:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Mode selection buttons
              Row(
                children: [
                  // Voice Mode
                  Expanded(
                    child: _buildModeButton(
                      mode: CoachingMode.voice,
                      icon: Icons.mic,
                      emoji: '🎤',
                      title: AppLocalizations.of(context)!.voiceModeTitle,
                      subtitle: AppLocalizations.of(context)!.voiceModeSubtitle,
                      isSelected: _selectedMode == CoachingMode.voice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Music Mode
                  Expanded(
                    child: _buildModeButton(
                      mode: CoachingMode.music,
                      icon: Icons.music_note,
                      emoji: '🎵',
                      title: AppLocalizations.of(context)!.musicModeTitle,
                      subtitle: AppLocalizations.of(context)!.musicModeSubtitle,
                      isSelected: _selectedMode == CoachingMode.music,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Remember choice checkbox
              GestureDetector(
                onTap: () {
                  setState(() {
                    _rememberChoice = !_rememberChoice;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _rememberChoice
                            ? CleanTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _rememberChoice
                              ? CleanTheme.primaryColor
                              : CleanTheme.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: _rememberChoice
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ricorda la mia scelta',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start button
              CleanButton(
                text: 'Inizia Esercizio',
                icon: Icons.play_arrow_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.pop(context);
                  widget.onModeSelected(_selectedMode, _rememberChoice);
                },
              ),

              // Skip intro option
              if (widget.onSkipIntro != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSkipIntro!();
                  },
                  child: Text(
                    'Salta introduzione',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required CoachingMode mode,
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? CleanTheme.primaryColor
                    : CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.3,
                color: CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
