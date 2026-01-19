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

  /// Whether this is a trial workout (athletic assessment)
  /// If true, logs are not sent to backend immediately, but timer and callbacks still fire.
  final bool isTrial;

  const SetLoggingWidget({
    super.key,
    required this.exercise,
    this.exerciseLog,
    required this.onCompletionChanged,
    this.onSetCompleted,
    this.onRestTimerSkipped,
    this.isTrial = false,
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
                Expanded(
                  flex: 2,
                  child: Text(
                    'PREC.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CleanTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
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
                Expanded(
                  flex: 2,
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
                Expanded(
                  flex: 2,
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
                const SizedBox(width: 32), // Space for checkbox
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
          Expanded(
            flex: 2,
            child: _loadingPrevious
                ? const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1),
                    ),
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
          Expanded(
            flex: 2,
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
          Expanded(
            flex: 2,
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
          Expanded(
            flex: 2,
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

          // Custom Checkbox Button
          GestureDetector(
            onTap: () => _toggleSet(setNumber, !isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? CleanTheme.primaryColor
                    : CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted
                      ? CleanTheme.primaryColor
                      : CleanTheme.borderSecondary,
                  width: 2,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : Icon(
                        Icons.check,
                        size: 20,
                        color: CleanTheme.borderSecondary,
                      ),
              ),
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

    // Start rest timer IMMEDIATELY after checking the set for instant feedback
    if (value && setNumber <= widget.exercise.sets && !_isRestTimerActive) {
      _startRestTimer();
    }

    // [NEW] Trial Workout Logic: Bypass backend logging, just do UI/Timer/Callback
    if (widget.isTrial) {
      if (value) {
        // Fire Callbacks
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
      }

      // Update completion status
      final allCompleted =
          _completedSets.values.where((v) => v).length == widget.exercise.sets;
      widget.onCompletionChanged(allCompleted);

      if (allCompleted && _showCoachingControls) {
        _stopRestTimer();
      }
      return;
    }

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
        if (!_showCoachingControls) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark futuristic background
            borderRadius: BorderRadius.circular(32), // Stadium shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with glowing indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    color: _coachingPlayer.isPlaying
                        ? const Color(0xFF00E676) // Neon Green when playing
                        : Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GIGI LIVE COACHING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Intro Button (Previous/Rewind styled)
                  _buildFuturisticButton(
                    icon: Icons.skip_previous_rounded,
                    label: 'INTRO',
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingPreExercise,
                    onTap: () => _coachingPlayer.playPreExercise(),
                  ),

                  // Divider
                  Container(width: 1, height: 24, color: Colors.white10),

                  // EXECUTION (Play styled - Main)
                  _buildMainPlayButton(
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingDuringExecution,
                    isPlaying:
                        _coachingPlayer.isPlaying &&
                        _coachingPlayer.state ==
                            CoachingPlayerState.playingDuringExecution,
                    onTap: () => _coachingPlayer.playDuringExecution(),
                  ),

                  // Divider
                  Container(width: 1, height: 24, color: Colors.white10),

                  // Outro Button (Next/Forward styled)
                  _buildFuturisticButton(
                    icon: Icons.skip_next_rounded,
                    label: 'FINALE',
                    isActive:
                        _coachingPlayer.state ==
                        CoachingPlayerState.playingPostExercise,
                    onTap: () => _coachingPlayer.playPostExercise(),
                  ),

                  // Stop Button (Red X or Stop)
                  if (_coachingPlayer.isPlaying) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _coachingPlayer.stop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFuturisticButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive
        ? const Color(0xFF00E676)
        : Colors.white; // Neon Green or White

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color.withValues(alpha: isActive ? 1.0 : 0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: isActive ? 1.0 : 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPlayButton({
    required bool isActive,
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00E676)
              : Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isActive ? Colors.black : Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
