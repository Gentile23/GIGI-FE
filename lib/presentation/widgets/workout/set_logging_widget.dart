import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../core/services/audio/voice_coaching_player.dart';

/// Data passed when a single set is completed
class SetCompletionData {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final int? rpe;
  final double? previousWeightKg;
  final bool isLastSet;

  const SetCompletionData({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.rpe,
    this.previousWeightKg,
    required this.isLastSet,
  });
}

class SetLoggingWidget extends StatefulWidget {
  final WorkoutExercise exercise;
  final ExerciseLogModel? exerciseLog;
  final Function(bool) onCompletionChanged;

  /// Called when a single set is checked - for voice coaching sync
  final Function(SetCompletionData)? onSetCompleted;

  /// Called when rest timer is skipped - for voice coaching sync
  final VoidCallback? onRestTimerSkipped;

  const SetLoggingWidget({
    super.key,
    required this.exercise,
    this.exerciseLog,
    required this.onCompletionChanged,
    this.onSetCompleted,
    this.onRestTimerSkipped,
  });

  @override
  State<SetLoggingWidget> createState() => _SetLoggingWidgetState();
}

class _SetLoggingWidgetState extends State<SetLoggingWidget> {
  final Map<int, double> _weights = {};
  final Map<int, int> _reps = {};
  final Map<int, int> _rpe = {};
  final Map<int, bool> _completedSets = {};
  final VoiceCoachingPlayer _coachingPlayer = VoiceCoachingPlayer();
  bool _showCoachingControls = false;

  // Previous workout data
  Map<int, Map<String, dynamic>>? _previousData;
  bool _loadingPrevious = true;

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerActive = false;
  final AudioPlayer _timerAudioPlayer = AudioPlayer();

  // Default rest time from exercise or 60 seconds
  int get _defaultRestSeconds =>
      widget.exercise.restSeconds > 0 ? widget.exercise.restSeconds : 60;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeCoaching();
    _loadPreviousData();
  }

  void _initializeCoaching() {
    if (widget.exercise.exercise.voiceCoaching?.isMultiPhase == true) {
      _coachingPlayer.setCoaching(
        widget.exercise.exercise.voiceCoaching!.multiPhase,
      );
      _showCoachingControls = true;
    }
  }

  void _initializeData() {
    for (int i = 1; i <= widget.exercise.sets; i++) {
      _reps[i] = int.tryParse(widget.exercise.reps) ?? 0;
      _rpe[i] = 7; // Default RPE

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
          _rpe[i] = setLog.rpe ?? 7;
          _completedSets[i] = setLog.completed;
        }
      }
    }
  }

  Future<void> _loadPreviousData() async {
    try {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      final data = await provider.getExerciseLastPerformance(
        widget.exercise.exercise.id,
      );

      if (data != null && data['sets'] != null) {
        final sets = data['sets'] as List;
        final previousMap = <int, Map<String, dynamic>>{};

        for (var set in sets) {
          // Safely parse weight_kg which may come as String or num from API
          dynamic weightValue = set['weight_kg'];
          double? parsedWeight;
          if (weightValue is num) {
            parsedWeight = weightValue.toDouble();
          } else if (weightValue is String) {
            parsedWeight = double.tryParse(weightValue);
          }

          previousMap[set['set_number'] as int] = {
            'reps': set['reps'],
            'weight_kg': parsedWeight,
            'rpe': set['rpe'],
          };
        }

        if (mounted) {
          setState(() {
            _previousData = previousMap;
            _loadingPrevious = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingPrevious = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPrevious = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _coachingPlayer.dispose();
    _restTimer?.cancel();
    _timerAudioPlayer.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    setState(() {
      _restSecondsRemaining = _defaultRestSeconds;
      _isRestTimerActive = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });

        // Play beep at 3, 2, 1
        if (_restSecondsRemaining <= 3 && _restSecondsRemaining > 0) {
          _timerAudioPlayer.play(AssetSource('sounds/beep.mp3'));
        }
      } else {
        _stopRestTimer();
        _timerAudioPlayer.play(AssetSource('sounds/complete.mp3'));
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isRestTimerActive = false;
      _restSecondsRemaining = 0;
    });
  }

  void _skipRestTimer() {
    _stopRestTimer();
    // Notify voice coaching that rest was skipped
    widget.onRestTimerSkipped?.call();
  }

  /// Safely format weight value that may come as String, double, int, or null from API
  String _formatWeight(dynamic value) {
    if (value == null) return '-';
    if (value is num) return value.toStringAsFixed(0);
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed?.toStringAsFixed(0) ?? '-';
    }
    return '-';
  }

  // Get color based on exercise type
  Color _getExerciseTypeColor() {
    switch (widget.exercise.exerciseType) {
      case 'cardio':
        return const Color(0xFFFF6B35); // Orange for cardio
      case 'mobility':
        return const Color(0xFF26A69A); // Teal for mobility
      case 'warmup':
        return const Color(0xFFFFB74D); // Amber for warmup
      default:
        return CleanTheme.primaryColor; // Default blue for strength
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getExerciseTypeColor();
    final isSpecialType = widget.exercise.exerciseType != 'strength';

    return Container(
      decoration: isSpecialType
          ? BoxDecoration(
              color: typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: typeColor.withValues(alpha: 0.3)),
            )
          : null,
      padding: isSpecialType ? const EdgeInsets.all(12) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Type Badge
          if (isSpecialType)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.exercise.exerciseType == 'cardio'
                        ? Icons.directions_run
                        : widget.exercise.exerciseType == 'mobility'
                        ? Icons.self_improvement
                        : Icons.whatshot,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.exercise.exerciseType.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          if (_showCoachingControls) _buildCoachingControls(),

          // Rest Timer (if active)
          if (_isRestTimerActive) _buildRestTimerWidget(),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'SET',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    'PREC.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CleanTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    'KG',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 50,
                  child: Text(
                    'REPS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 45,
                  child: Text(
                    'RPE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),

          ...List.generate(widget.exercise.sets, (index) {
            final setNumber = index + 1;
            return _buildSetRow(setNumber);
          }),
        ],
      ),
    );
  }

  Widget _buildRestTimerWidget() {
    final progress = _restSecondsRemaining / _defaultRestSeconds;
    final minutes = _restSecondsRemaining ~/ 60;
    final seconds = _restSecondsRemaining % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: CleanTheme.accentBlue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Recupero',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: CleanTheme.borderPrimary,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _restSecondsRemaining <= 3
                        ? CleanTheme.accentRed
                        : CleanTheme.accentBlue,
                  ),
                ),
              ),
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _restSecondsRemaining <= 3
                      ? CleanTheme.accentRed
                      : CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skipRestTimer,
            child: Text(
              'Salta',
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int setNumber) {
    final isCompleted = _completedSets[setNumber] ?? false;
    final previousSet = _previousData?[setNumber];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? CleanTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set Number
          SizedBox(
            width: 32,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? CleanTheme.accentGreen
                    : CleanTheme.borderSecondary,
                border: Border.all(
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : CleanTheme.borderPrimary,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(
                        '$setNumber',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
              ),
            ),
          ),

          // Previous Data
          SizedBox(
            width: 55,
            child: _loadingPrevious
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1),
                  )
                : Text(
                    previousSet != null
                        ? '${_formatWeight(previousSet['weight_kg'])}x${previousSet['reps'] ?? '-'}'
                        : '-',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CleanTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          // Weight Input
          SizedBox(
            width: 55,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textPrimary,
                ),
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

          const SizedBox(width: 6),

          // Reps Input
          SizedBox(
            width: 50,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textPrimary,
                ),
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

          const SizedBox(width: 6),

          // RPE Selector
          SizedBox(
            width: 45,
            child: GestureDetector(
              onTap: () => _showRPEPicker(setNumber),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: _getRPEColor(
                    _rpe[setNumber] ?? 7,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getRPEColor(
                      _rpe[setNumber] ?? 7,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_rpe[setNumber] ?? 7}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getRPEColor(_rpe[setNumber] ?? 7),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Checkbox
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: isCompleted,
              activeColor: CleanTheme.primaryColor,
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

  Color _getRPEColor(int rpe) {
    if (rpe <= 4) return CleanTheme.accentGreen;
    if (rpe <= 6) return Colors.amber;
    if (rpe <= 8) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }

  void _showRPEPicker(int setNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RPE - Rate of Perceived Exertion',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quanto ti è sembrato difficile questo set?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (index) {
                final rpeValue = index + 1;
                final isSelected = _rpe[setNumber] == rpeValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rpe[setNumber] = rpeValue;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getRPEColor(rpeValue)
                          : _getRPEColor(rpeValue).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getRPEColor(rpeValue),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rpeValue',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : _getRPEColor(rpeValue),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1-4: Facile',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.accentGreen,
                  ),
                ),
                Text(
                  '5-6: Medio',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.amber),
                ),
                Text(
                  '7-8: Difficile',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.accentOrange,
                  ),
                ),
                Text(
                  '9-10: Massimo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.accentRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSet(int setNumber, bool? value) async {
    if (value == null) return;

    setState(() {
      _completedSets[setNumber] = value;
    });

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

    String? exerciseLogId = widget.exerciseLog?.id;

    if (exerciseLogId == null) {
      final newLog = await provider.addExerciseLog(
        exerciseId: widget.exercise.exercise.id,
        orderIndex: 0,
        exerciseType: 'main',
      );
      exerciseLogId = newLog?.id;
    }

    if (exerciseLogId != null && value) {
      await provider.addSetLog(
        exerciseLogId: exerciseLogId,
        setNumber: setNumber,
        reps: _reps[setNumber] ?? 0,
        weightKg: _weights[setNumber],
        rpe: _rpe[setNumber],
        completed: true,
      );

      // Call voice coaching sync callback with set data
      final previousSet = _previousData?[setNumber];
      widget.onSetCompleted?.call(
        SetCompletionData(
          setNumber: setNumber,
          weightKg: _weights[setNumber],
          reps: _reps[setNumber],
          rpe: _rpe[setNumber],
          previousWeightKg: previousSet?['weight_kg'] as double?,
          isLastSet: setNumber == widget.exercise.sets,
        ),
      );

      // Auto-start rest timer after completing a set (if not last set)
      if (setNumber < widget.exercise.sets && !_isRestTimerActive) {
        _startRestTimer();
      }
    }

    final allCompleted =
        _completedSets.values.where((v) => v).length == widget.exercise.sets;
    widget.onCompletionChanged(allCompleted);

    if (allCompleted && _showCoachingControls) {
      _stopRestTimer(); // Stop timer if all sets complete
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
            color: CleanTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CleanTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.headset_outlined,
                    color: CleanTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voice Coaching',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_coachingPlayer.isPlaying)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: CleanTheme.primaryColor,
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
                    label: 'Durante',
                    onPressed: () => _coachingPlayer.playDuringExecution(),
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingDuringExecution,
                  ),
                  _buildCoachingButton(
                    icon: Icons.check_circle_outline,
                    label: 'Finale',
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
            color: isActive ? CleanTheme.primaryColor : CleanTheme.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: CleanTheme.primaryColor, width: 1.5),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isActive ? Colors.white : CleanTheme.primaryColor,
            iconSize: 24,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isActive
                ? CleanTheme.primaryColor
                : CleanTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
