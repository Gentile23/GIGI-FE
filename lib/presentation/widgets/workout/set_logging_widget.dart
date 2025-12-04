import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitgenius/core/constants/app_colors.dart';
import 'package:fitgenius/core/constants/app_text_styles.dart';
import 'package:fitgenius/data/models/workout_model.dart';
import 'package:fitgenius/data/models/workout_log_model.dart';
import 'package:fitgenius/providers/workout_log_provider.dart';
import 'package:fitgenius/core/services/audio/voice_coaching_player.dart';

class SetLoggingWidget extends StatefulWidget {
  final WorkoutExercise exercise;
  final ExerciseLogModel? exerciseLog;
  final Function(bool) onCompletionChanged;

  const SetLoggingWidget({
    super.key,
    required this.exercise,
    this.exerciseLog,
    required this.onCompletionChanged,
  });

  @override
  State<SetLoggingWidget> createState() => _SetLoggingWidgetState();
}

class _SetLoggingWidgetState extends State<SetLoggingWidget> {
  // Local state to track inputs before saving
  final Map<int, double> _weights = {};
  final Map<int, int> _reps = {};
  final Map<int, bool> _completedSets = {};
  final VoiceCoachingPlayer _coachingPlayer = VoiceCoachingPlayer();
  bool _showCoachingControls = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeCoaching();
  }

  void _initializeCoaching() {
    // Initialize coaching if available
    if (widget.exercise.exercise.voiceCoaching?.isMultiPhase == true) {
      _coachingPlayer.setCoaching(
        widget.exercise.exercise.voiceCoaching!.multiPhase,
      );
      _showCoachingControls = true;
    }
  }

  void _initializeData() {
    // Initialize with default values from exercise plan
    for (int i = 1; i <= widget.exercise.sets; i++) {
      _reps[i] = int.tryParse(widget.exercise.reps) ?? 0;

      // If we have existing logs, use them
      if (widget.exerciseLog != null) {
        final setLog = widget.exerciseLog!.setLogs.firstWhere(
          (s) => s.setNumber == i,
          orElse: () => SetLogModel(
            id: '',
            exerciseLogId: '',
            setNumber: i,
            reps: 0,
            completed: false,
          ),
        );

        if (setLog.id.isNotEmpty) {
          _weights[i] = setLog.weightKg ?? 0;
          _reps[i] = setLog.reps;
          _completedSets[i] = setLog.completed;
        }
      }
    }
  }

  @override
  void dispose() {
    _coachingPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Voice Coaching Controls
        if (_showCoachingControls) _buildCoachingControls(),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'SET',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'PREVIOUS',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'KG',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  'REPS',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // Checkbox space
            ],
          ),
        ),

        // Sets
        ...List.generate(widget.exercise.sets, (index) {
          final setNumber = index + 1;
          return _buildSetRow(setNumber);
        }),
      ],
    );
  }

  Widget _buildSetRow(int setNumber) {
    final isCompleted = _completedSets[setNumber] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set Number
          SizedBox(
            width: 40,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundLight,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text('$setNumber', style: AppTextStyles.bodySmall),
              ),
            ),
          ),

          // Previous (Placeholder for now)
          Expanded(
            child: Text(
              '-',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Weight Input
          SizedBox(
            width: 60,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  _weights[setNumber] = double.tryParse(value) ?? 0;
                },
                controller:
                    TextEditingController(
                        text: _weights[setNumber]?.toString() ?? '',
                      )
                      ..selection = TextSelection.fromPosition(
                        TextPosition(
                          offset:
                              (_weights[setNumber]?.toString() ?? '').length,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Reps Input
          SizedBox(
            width: 60,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  _reps[setNumber] = int.tryParse(value) ?? 0;
                },
                controller:
                    TextEditingController(
                        text: _reps[setNumber]?.toString() ?? '',
                      )
                      ..selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: (_reps[setNumber]?.toString() ?? '').length,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Checkbox
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: isCompleted,
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) => _toggleSet(setNumber, value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSet(int setNumber, bool? value) async {
    if (value == null) return;

    setState(() {
      _completedSets[setNumber] = value;
    });

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

    // Ensure we have an exercise log first
    String? exerciseLogId = widget.exerciseLog?.id;

    if (exerciseLogId == null) {
      // Create exercise log if it doesn't exist
      final newLog = await provider.addExerciseLog(
        exerciseId: widget.exercise.exercise.id,
        orderIndex: 0, // Should be passed or calculated
        exerciseType: 'main',
      );
      exerciseLogId = newLog?.id;
    }

    if (exerciseLogId != null && value) {
      // Log the set
      await provider.addSetLog(
        exerciseLogId: exerciseLogId,
        setNumber: setNumber,
        reps: _reps[setNumber] ?? 0,
        weightKg: _weights[setNumber],
        completed: true,
      );
    }

    // Check if all sets are completed to update parent
    final allCompleted =
        _completedSets.values.where((v) => v).length == widget.exercise.sets;
    widget.onCompletionChanged(allCompleted);

    // Auto-play post-exercise audio if all sets are complete
    if (allCompleted && _showCoachingControls) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _coachingPlayer.playPostExercise();
        }
      });
    }
  }

  Widget _buildCoachingControls() {
    return ListenableBuilder(
      listenable: _coachingPlayer,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryNeon.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.headset, color: AppColors.primaryNeon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Coaching',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_coachingPlayer.isPlaying)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryNeon,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCoachingButton(
                    icon: Icons.play_circle_outline,
                    label: 'Intro',
                    onPressed: () => _coachingPlayer.playPreExercise(),
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingPreExercise,
                  ),
                  _buildCoachingButton(
                    icon: Icons.fitness_center,
                    label: 'During',
                    onPressed: () => _coachingPlayer.playDuringExecution(),
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingDuringExecution,
                  ),
                  _buildCoachingButton(
                    icon: Icons.check_circle_outline,
                    label: 'Wrap-up',
                    onPressed: () => _coachingPlayer.playPostExercise(),
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingPostExercise,
                  ),
                  if (_coachingPlayer.isPlaying)
                    _buildCoachingButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      onPressed: () => _coachingPlayer.stop(),
                      isActive: false,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoachingButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryNeon : AppColors.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryNeon, width: 1.5),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isActive ? Colors.white : AppColors.primaryNeon,
            iconSize: 24,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.primaryNeon : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
