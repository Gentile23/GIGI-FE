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
import '../../../core/services/haptic_service.dart';

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

  /// Called when rest timer state changes — parent shows fullscreen overlay
  /// Parameters: (bool isActive, int secondsRemaining, int totalSeconds)
  final Function(bool isActive, int secondsRemaining, int totalSeconds)?
  onRestTimerStateChanged;

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
    this.onRestTimerStateChanged,
    this.isTrial = false,
  });

  @override
  State<SetLoggingWidget> createState() => SetLoggingWidgetState();
}

class SetLoggingWidgetState extends State<SetLoggingWidget> {
  final Map<int, double> _weights = {};
  final Map<int, int> _reps = {};
  final Map<int, int> _rpe = {};
  final Map<int, bool> _completedSets = {};
  final VoiceCoachingPlayer _coachingPlayer = VoiceCoachingPlayer();
  bool _showCoachingControls = false;

  // Persistent TextEditingControllers — created once, never recreated on rebuild
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  // Previous workout data
  Map<int, Map<String, dynamic>>? _previousData;

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerActive = false;
  final AudioPlayer _timerAudioPlayer = AudioPlayer();
  final AudioPlayer _successAudioPlayer = AudioPlayer();
  final Source _successSource = AssetSource('sounds/success.wav');

  // Default rest time from exercise or 60 seconds
  int get _defaultRestSeconds =>
      widget.exercise.restSeconds > 0 ? widget.exercise.restSeconds : 60;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
    _initializeCoaching();
    _loadPreviousData();
    // Pre-set success source for zero-latency playback
    _successAudioPlayer.setSource(_successSource);
  }

  /// Create persistent TextEditingControllers for each set — called once in initState
  void _initializeControllers() {
    for (int i = 1; i <= widget.exercise.sets; i++) {
      // Weight controller
      final weightVal = _weights[i];
      final weightText = weightVal != null && weightVal > 0
          ? (weightVal % 1 == 0
                ? weightVal.toInt().toString()
                : weightVal.toStringAsFixed(1))
          : '';
      _weightControllers[i] = TextEditingController(text: weightText);
      _weightControllers[i]!.addListener(() {
        final parsed = double.tryParse(_weightControllers[i]!.text);
        if (parsed != null) {
          _weights[i] = parsed;
        } else if (_weightControllers[i]!.text.isEmpty) {
          _weights[i] = 0;
        }
      });

      // Reps controller
      final repsVal = _reps[i];
      final repsText = repsVal != null && repsVal > 0 ? repsVal.toString() : '';
      _repsControllers[i] = TextEditingController(text: repsText);
      _repsControllers[i]!.addListener(() {
        final parsed = int.tryParse(_repsControllers[i]!.text);
        if (parsed != null) {
          _reps[i] = parsed;
        } else if (_repsControllers[i]!.text.isEmpty) {
          _reps[i] = 0;
        }
      });
    }
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
          });
        }
      } else {
        // No previous data found, nothing to update
      }
    } catch (e) {
      // Silently handle — previous data is nice-to-have, not critical
    }
  }

  @override
  void dispose() {
    // Dispose persistent controllers to prevent memory leaks
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    _coachingPlayer.dispose();
    _restTimer?.cancel();
    _timerAudioPlayer.dispose();
    _successAudioPlayer.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    setState(() {
      _restSecondsRemaining = _defaultRestSeconds;
      _isRestTimerActive = true;
    });

    // Notify parent to show fullscreen timer overlay
    widget.onRestTimerStateChanged?.call(
      true,
      _defaultRestSeconds,
      _defaultRestSeconds,
    );

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });

        // Notify parent of countdown
        widget.onRestTimerStateChanged?.call(
          true,
          _restSecondsRemaining,
          _defaultRestSeconds,
        );

        // Play countdown tick every second during last 3 seconds
        if (_restSecondsRemaining <= 3 && _restSecondsRemaining > 0) {
          _timerAudioPlayer.stop().then(
            (_) => _timerAudioPlayer.play(AssetSource('sounds/secondi.mp3')),
          );
        }
      } else {
        _stopRestTimer();
        _timerAudioPlayer.stop().then(
          (_) => _timerAudioPlayer.play(AssetSource('sounds/tempo-finito.mp3')),
        );
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isRestTimerActive = false;
      _restSecondsRemaining = 0;
    });
    // Notify parent to hide fullscreen timer
    widget.onRestTimerStateChanged?.call(false, 0, 0);
  }

  /// Skip the rest timer — called when parent overlay's skip button is pressed
  /// Also fires onRestTimerSkipped for voice coaching sync
  void skipRestTimer() {
    _stopRestTimer();
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
        return CleanTheme.accentOrange; // Orange for cardio
      case 'mobility':
        return CleanTheme.accentBlue; // Blue for mobility
      case 'warmup':
        return CleanTheme.accentYellow; // Yellow for warmup
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
                    color: CleanTheme.textOnPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.exercise.exerciseType.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),

          if (_showCoachingControls) _buildCoachingControls(),

          // Rest Timer is now rendered fullscreen by parent via onRestTimerStateChanged

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

  Widget _buildSetRow(int setNumber) {
    final isCompleted = _completedSets[setNumber] ?? false;
    final previousSet = _previousData?[setNumber];
    final prevWeight = previousSet != null
        ? _formatWeight(previousSet['weight_kg'])
        : null;
    final prevReps = previousSet?['reps']?.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [
                  CleanTheme.accentGreen.withValues(alpha: 0.08),
                  CleanTheme.accentGreen.withValues(alpha: 0.03),
                ],
              )
            : null,
        color: isCompleted ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCompleted
            ? Border.all(
                color: CleanTheme.accentGreen.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set Number Badge
          SizedBox(
            width: 36,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? CleanTheme.accentGreen
                    : CleanTheme.primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : CleanTheme.borderPrimary,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: CleanTheme.textOnPrimary,
                      )
                    : Text(
                        '$setNumber',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
              ),
            ),
          ),

          // Weight Input — Premium with previous data subtitle
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? CleanTheme.accentGreen.withValues(alpha: 0.06)
                        : CleanTheme.primaryColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCompleted
                          ? CleanTheme.accentGreen.withValues(alpha: 0.3)
                          : CleanTheme.borderPrimary,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _weightControllers[setNumber],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? CleanTheme.accentGreen
                          : CleanTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      hintText: 'kg',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textTertiary,
                      ),
                    ),
                    enabled: !isCompleted,
                  ),
                ),
                // Previous data subtitle
                if (prevWeight != null && prevWeight != '-') ...[
                  const SizedBox(height: 2),
                  Text(
                    'prev: ${prevWeight}kg',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Reps Input — Premium with previous data subtitle
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? CleanTheme.accentGreen.withValues(alpha: 0.06)
                        : CleanTheme.primaryColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCompleted
                          ? CleanTheme.accentGreen.withValues(alpha: 0.3)
                          : CleanTheme.borderPrimary,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: _repsControllers[setNumber],
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? CleanTheme.accentGreen
                          : CleanTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      hintText: widget.exercise.reps,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textTertiary,
                      ),
                    ),
                    enabled: !isCompleted,
                  ),
                ),
                // Previous data subtitle
                if (prevReps != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'prev: $prevReps',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // RPE Selector — Compact
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: isCompleted ? null : () => _showRPEPicker(setNumber),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _getRPEColor(
                    _rpe[setNumber] ?? 7,
                  ).withValues(alpha: isCompleted ? 0.1 : 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getRPEColor(
                      _rpe[setNumber] ?? 7,
                    ).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_rpe[setNumber] ?? 7}',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _getRPEColor(_rpe[setNumber] ?? 7),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Premium Checkbox Button
          GestureDetector(
            onTap: () {
              if (!isCompleted) {
                // Haptic and sound IMMEDIATELY on tap for zero perceived latency
                HapticService.mediumTap();
                _successAudioPlayer
                    .resume(); // Resume is faster than play if source is set
                // Also reset for next time
                _successAudioPlayer.setSource(_successSource);
              }
              _toggleSet(setNumber, !isCompleted);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? CleanTheme.accentGreen
                    : CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : CleanTheme.borderPrimary,
                  width: 2,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.check_rounded,
                  size: 22,
                  color: isCompleted
                      ? CleanTheme.textOnPrimary
                      : CleanTheme.textTertiary,
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
    if (rpe <= 6) return CleanTheme.accentYellow;
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
                              ? CleanTheme.textOnPrimary
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
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.accentYellow,
                  ),
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
      // Sound is now handled in onTap for faster response
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
            color: CleanTheme.surfaceColor, // Dark futuristic background
            borderRadius: BorderRadius.circular(32), // Stadium shape
            boxShadow: [
              BoxShadow(
                color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: CleanTheme.borderPrimary, width: 1),
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
                        ? CleanTheme
                              .accentGreen // Neon Green when playing
                        : CleanTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GIGI LIVE COACHING',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: CleanTheme.textSecondary,
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
                  Container(
                    width: 1,
                    height: 24,
                    color: CleanTheme.borderPrimary,
                  ),

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
                  Container(
                    width: 1,
                    height: 24,
                    color: CleanTheme.borderPrimary,
                  ),

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
                          color: CleanTheme.accentRed.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: CleanTheme.accentRed,
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
        ? CleanTheme.accentGreen
        : CleanTheme.textOnPrimary; // Neon Green or White

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
          color: isActive ? CleanTheme.accentGreen : CleanTheme.surfaceColor,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isActive ? CleanTheme.primaryColor : CleanTheme.textOnPrimary,
          size: 32,
        ),
      ),
    );
  }
}
