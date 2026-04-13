import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/workout_log_model.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../core/services/audio/voice_coaching_player.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/rest_timer_service.dart';

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
  final String restTimerId;
  final String workoutDayId;
  final ExerciseLogModel? exerciseLog;
  final Function(bool) onCompletionChanged;

  /// Called when a single set is checked - for voice coaching sync
  final Function(SetCompletionData)? onSetCompleted;

  /// Called when rest timer is skipped - for voice coaching sync
  final VoidCallback? onRestTimerSkipped;

  /// Called when rest timer state changes — parent shows fullscreen overlay
  /// Parameters: (bool isActive, int secondsRemaining, int totalSeconds)
  /// Parameters: (bool isActive, int secondsRemaining, int totalSeconds, int setNumber)
  final Function(
    bool isActive,
    int secondsRemaining,
    int totalSeconds,
    int setNumber,
  )?
  onRestTimerStateChanged;

  /// Whether this is a trial workout (athletic assessment)
  /// If true, logs are not sent to backend immediately, but timer and callbacks still fire.
  final bool isTrial;

  /// Custom debounce time for auto-saving
  final Duration debounceTime;

  const SetLoggingWidget({
    super.key,
    required this.exercise,
    required this.restTimerId,
    required this.workoutDayId,
    this.exerciseLog,
    required this.onCompletionChanged,
    this.onSetCompleted,
    this.onRestTimerSkipped,
    this.onRestTimerStateChanged,
    this.isTrial = false,
    this.debounceTime = const Duration(milliseconds: 500),
  });

  @override
  State<SetLoggingWidget> createState() => SetLoggingWidgetState();
}

class SetLoggingWidgetState extends State<SetLoggingWidget> {
  // --- Public methods to access controllers from overlay ---
  TextEditingController? getWeightController(int setNumber) =>
      _weightControllers[setNumber];
  TextEditingController? getRepsController(int setNumber) =>
      _repsControllers[setNumber];
  int getRpe(int setNumber) => _rpe[setNumber] ?? 7;

  List<SetCompletionData> getCompletedSetEntries() {
    final entries = <SetCompletionData>[];
    for (int setNumber = 1; setNumber <= widget.exercise.sets; setNumber++) {
      if (!(_completedSets[setNumber] ?? false)) continue;
      entries.add(
        SetCompletionData(
          setNumber: setNumber,
          weightKg: _weights[setNumber],
          reps: _reps[setNumber],
          rpe: _rpe[setNumber],
          previousWeightKg: null,
          isLastSet: setNumber == widget.exercise.sets,
        ),
      );
    }
    return entries;
  }

  void updateRpe(int setNumber, int value) {
    if (_rpe[setNumber] != value) {
      setState(() {
        _rpe[setNumber] = value;
      });
      _scheduleAutoSave(setNumber);
    }
  }

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

  // Preset (Target) data from the workout plan - kept separate to show alongside previous data
  final Map<int, String> _presetReps = {};

  // Rest timer
  bool _isRestTimerActive = false;
  final AudioPlayer _successAudioPlayer = AudioPlayer();
  final Source _successSource = AssetSource('sounds/success.wav');
  RestTimerService? _restTimerService;

  // Default rest time from exercise or 60 seconds
  int get _defaultRestSeconds =>
      widget.exercise.restSeconds > 0 ? widget.exercise.restSeconds : 60;

  String _formatWeightForInput(double weight) {
    if (weight % 1 == 0) return weight.toInt().toString();
    return weight.toStringAsFixed(1).replaceAll('.', ',');
  }

  double? _parseWeightInput(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    if (normalized.isEmpty ||
        normalized == '.' ||
        normalized.endsWith('.') ||
        normalized.split('.').length > 2) {
      return null;
    }
    return double.tryParse(normalized);
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeControllers();
    _initializeCoaching();
    _loadPreviousData();
    // Pre-load sounds for zero-latency playback
    _successAudioPlayer.setSource(_successSource);
    // Use low latency mode if available (depends on audioplayers version, but usually default is fine)
  }

  @override
  void didUpdateWidget(SetLoggingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the exercise log has been updated from outside (e.g. backend refresh)
    // and we are not currently editing, sync local state.
    if (widget.exerciseLog != oldWidget.exerciseLog &&
        widget.exerciseLog != null) {
      _syncStateWithLog();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final restTimerService = context.read<RestTimerService>();
    if (_restTimerService == restTimerService) return;

    _restTimerService?.removeListener(_handleRestTimerServiceChanged);
    _restTimerService = restTimerService;
    _restTimerService?.addListener(_handleRestTimerServiceChanged);
    _handleRestTimerServiceChanged();
  }

  void _handleRestTimerServiceChanged() {
    final restTimerService = _restTimerService;
    if (restTimerService == null || !mounted) return;

    final state = restTimerService.state;
    final isThisTimer =
        state.exerciseId == widget.restTimerId &&
        state.workoutDayId == widget.workoutDayId;

    if (state.isActive && isThisTimer) {
      setState(() {
        _isRestTimerActive = true;
      });
      return;
    }

    if (_isRestTimerActive && isThisTimer) {
      setState(() {
        _isRestTimerActive = false;
      });
    }
  }

  void _syncStateWithLog() {
    if (widget.exerciseLog == null) return;

    setState(() {
      for (final setLog in widget.exerciseLog!.setLogs) {
        final num = setLog.setNumber;
        _weights[num] = setLog.weightKg ?? 0;
        _reps[num] = setLog.reps;
        _rpe[num] = setLog.rpe ?? 0;
        _completedSets[num] = setLog.completed;

        // Update controllers if they exist
        final weightController = _weightControllers[num];
        if (weightController != null) {
          final newText = _formatWeightForInput(_weights[num]!);
          if (weightController.text != newText &&
              !_manuallyEditedWeights.contains(num)) {
            weightController.text = newText;
          }
        }

        final repsController = _repsControllers[num];
        if (repsController != null && !_manuallyEditedReps.contains(num)) {
          final newText = _reps[num]!.toString();
          if (repsController.text != newText) {
            repsController.text = newText;
          }
        }
      }
    });
  }

  /// Create persistent TextEditingControllers for each set — called once in initState
  void _initializeControllers() {
    for (int i = 1; i <= widget.exercise.sets; i++) {
      // Weight controller
      final weightVal = _weights[i];
      final weightText = weightVal != null && weightVal > 0
          ? _formatWeightForInput(weightVal)
          : '';
      final weightController = TextEditingController(text: weightText);
      _weightControllers[i] = weightController;

      weightController.addListener(() {
        final text = weightController.text;
        final parsed = _parseWeightInput(text);

        // PERSISTENCE FIX: Only update weight and trigger auto-fill if we have a valid positive number.
        // If the user clears the field to type a new number, we don't zero it out immediately.
        if (parsed != null && parsed > 0 && parsed != _weights[i]) {
          setState(() {
            _weights[i] = parsed;
            _handleWeightChange(i, parsed);
          });
        }
        // If it's explicitly '0', we allow it, but we don't trigger auto-fill/deletion logic on empty.
        else if (text == '0' && _weights[i] != 0) {
          setState(() {
            _weights[i] = 0;
            _handleWeightChange(i, 0);
          });
        }
      });

      // Reps controller
      final repsVal = _reps[i];
      final repsText = repsVal != null && repsVal > 0 ? repsVal.toString() : '';
      final repsController = TextEditingController(text: repsText);
      _repsControllers[i] = repsController;

      repsController.addListener(() {
        final text = repsController.text;
        final parsed = int.tryParse(text);
        if (parsed != null && parsed != _reps[i]) {
          setState(() {
            _reps[i] = parsed;
            _manuallyEditedReps.add(i); // Track manual edit
          });
          _scheduleAutoSave(i);
        } else if (text.isEmpty && _reps[i] != 0) {
          setState(() {
            _reps[i] = 0;
            _manuallyEditedReps.add(i); // Track manual edit
          });
          _scheduleAutoSave(i);
        }
      });
    }
  }

  // Map to track manual overrides to auto-fill
  final Set<int> _manuallyEditedWeights = {};
  final Set<int> _manuallyEditedReps = {};

  // Map for debounce timers
  final Map<int, Timer?> _autoSaveTimers = {};

  void _handleWeightChange(int setNumber, double weight) {
    _manuallyEditedWeights.add(setNumber);

    // Auto-fill subsequent sets that haven't been manually edited
    for (int i = setNumber + 1; i <= widget.exercise.sets; i++) {
      if (!_manuallyEditedWeights.contains(i)) {
        _weights[i] = weight;
        final controller = _weightControllers[i];
        if (controller != null) {
          final newText = _formatWeightForInput(weight);

          if (controller.text != newText) {
            controller.text = newText;
          }
        }
      }
    }

    _scheduleAutoSave(setNumber);
  }

  void _scheduleAutoSave(int setNumber) {
    _autoSaveTimers[setNumber]?.cancel();
    _autoSaveTimers[setNumber] = Timer(widget.debounceTime, () {
      _persistSetData(setNumber);
    });
  }

  Future<void> _persistSetData(int setNumber) async {
    if (widget.isTrial) return;

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    final isCompleted = _completedSets[setNumber] ?? false;

    // If set is already in a session, update it
    final setLogId = widget.exerciseLog?.setLogs
        .firstWhere(
          (s) => s.setNumber == setNumber,
          orElse: () => SetLogModel(
            id: '',
            exerciseLogId: '',
            setNumber: setNumber,
            reps: 0,
          ),
        )
        .id;

    if (setLogId != null && setLogId.isNotEmpty) {
      await provider.updateSetLog(
        setLogId: setLogId,
        exerciseLogId: widget.exerciseLog!.id,
        reps: _reps[setNumber],
        weightKg: _weights[setNumber],
        rpe: _rpe[setNumber],
        completed: isCompleted,
      );
    } else if (isCompleted) {
      // If not yet completed but data is being entered, we might want to wait or
      // proactively create a set log. For now, we follow the existing pattern
      // where _toggleSet handles the initial creation.
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
    final repsList = widget.exercise.reps
        .split(',')
        .map((s) => s.trim())
        .toList();

    for (int i = 1; i <= widget.exercise.sets; i++) {
      int defaultReps = 0;
      String currentTargetValue = '10';
      if (repsList.isNotEmpty) {
        final repString = i <= repsList.length
            ? repsList[i - 1]
            : repsList.last;
        currentTargetValue = repString;
        final match = RegExp(r'(\d+)').firstMatch(repString);
        if (match != null) {
          defaultReps = int.parse(match.group(1)!);
        }
      }
      _presetReps[i] = currentTargetValue;
      _reps[i] = defaultReps;
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

      if (data != null && data['has_previous'] == true) {
        final sets = data['sets'] as List;
        final previousMap = <int, Map<String, dynamic>>{};

        for (var set in sets) {
          // Safely parse weight_kg which may come as String or num from API
          dynamic weightValue = set['weight_kg'];
          double? parsedWeight;
          if (weightValue is num) {
            parsedWeight = weightValue.toDouble();
          } else if (weightValue is String) {
            parsedWeight = _parseWeightInput(weightValue);
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
            // Auto-populate weight & reps controllers with previous data if current is empty
            for (var entry in previousMap.entries) {
              final setNum = entry.key;
              final prevWeight = entry.value['weight_kg'];
              final prevReps = entry.value['reps'];

              // Sync Weight
              if (_weightControllers.containsKey(setNum) &&
                  (_weightControllers[setNum]!.text.isEmpty ||
                      _weightControllers[setNum]!.text == '0')) {
                if (prevWeight != null && prevWeight > 0) {
                  _weights[setNum] = prevWeight.toDouble();
                  _weightControllers[setNum]!.text = _formatWeightForInput(
                    prevWeight.toDouble(),
                  );
                }
              }

              // Sync Reps
              if (_repsControllers.containsKey(setNum) &&
                  (_repsControllers[setNum]!.text.isEmpty ||
                      _repsControllers[setNum]!.text == '0' ||
                      !_manuallyEditedReps.contains(setNum))) {
                if (prevReps != null && prevReps > 0) {
                  _reps[setNum] = prevReps;
                  _repsControllers[setNum]!.text = prevReps.toString();
                }
              }
            }
          });
        }
      }
    } catch (e) {
      // Silently handle
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
    _restTimerService?.removeListener(_handleRestTimerServiceChanged);
    _coachingPlayer.dispose();
    _successAudioPlayer.dispose();
    for (final timer in _autoSaveTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _startRestTimer(int setNumber) async {
    setState(() {
      _isRestTimerActive = true;
    });

    await context.read<RestTimerService>().start(
      workoutDayId: widget.workoutDayId,
      exerciseId: widget.restTimerId,
      setNumber: setNumber,
      totalSeconds: _defaultRestSeconds,
    );
  }

  Future<void> _stopRestTimer() async {
    await context.read<RestTimerService>().skip();
    setState(() {
      _isRestTimerActive = false;
    });
  }

  /// Skip the rest timer — called when parent overlay's skip button is pressed
  /// Also fires onRestTimerSkipped for voice coaching sync
  void skipRestTimer() {
    _stopRestTimer();
    widget.onRestTimerSkipped?.call();
  }

  // Get color based on exercise type
  Color _getExerciseTypeColor() {
    switch (widget.exercise.exerciseType) {
      case 'cardio':
        return CleanTheme.accentRed;
      case 'mobility':
        return CleanTheme.accentOrange;
      case 'warmup':
        return CleanTheme.accentOrange;
      default:
        return CleanTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getExerciseTypeColor();
    final isSpecialType = widget.exercise.exerciseType != 'strength';
    final isCardioMobility =
        widget.exercise.exerciseType == 'cardio' ||
        widget.exercise.exerciseType == 'mobility' ||
        widget.exercise.exerciseType == 'warmup';

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

          // Header — columns change based on exercise type
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
                if (!isCardioMobility) ...[
                  // Strength: KG + REPS
                  Expanded(
                    flex: 3,
                    child: Text(
                      'KG',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'REPS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RPE for strength only
                  Expanded(
                    flex: 2,
                    child: Text(
                      'RPE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  // Cardio/Mobility/Warmup: only DURATA
                  Expanded(
                    flex: 6,
                    child: Text(
                      widget.exercise.exerciseType == 'cardio'
                          ? 'DURATA'
                          : 'DURATA / HOLD',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textSecondary,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(width: 40), // Space for checkbox
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
    final isCardioMobility =
        widget.exercise.exerciseType == 'cardio' ||
        widget.exercise.exerciseType == 'mobility' ||
        widget.exercise.exerciseType == 'warmup';

    return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      CleanTheme.accentGreen.withValues(alpha: 0.07),
                      Colors.transparent,
                    ],
                  )
                : null,
            color: isCompleted ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isCompleted
                ? Border.all(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.25),
                    width: 1,
                  )
                : null,
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: CleanTheme.accentGreen.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 3,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? CleanTheme.accentGreen
                        : CleanTheme.chromeSubtle,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Set Number Badge
                      SizedBox(
                        width: 36,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 14), // Offset for labels
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted
                                    ? CleanTheme.accentGreen
                                    : CleanTheme.steelDark.withValues(
                                        alpha: 0.06,
                                      ),
                                border: Border.all(
                                  color: isCompleted
                                      ? CleanTheme.accentGreen
                                      : CleanTheme.chromeGray.withValues(
                                          alpha: 0.6,
                                        ),
                                  width: isCompleted ? 0 : 1.5,
                                ),
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 13,
                                        color: CleanTheme.textOnPrimary,
                                      )
                                    : Text(
                                        '$setNumber',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: CleanTheme.textPrimary,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Input Columns
                      if (!isCardioMobility) ...[
                        // Weight Column
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? CleanTheme.accentGreen.withValues(
                                          alpha: 0.06,
                                        )
                                      : CleanTheme.chromeSubtle.withValues(
                                          alpha: 0.5,
                                        ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isCompleted
                                        ? CleanTheme.accentGreen.withValues(
                                            alpha: 0.3,
                                          )
                                        : CleanTheme.borderSecondary,
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  controller: _weightControllers[setNumber],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*([,.]\d*)?$'),
                                    ),
                                  ],
                                  scrollPadding: const EdgeInsets.only(
                                    bottom: 120,
                                  ),
                                  onTap: () {
                                    final isGhost =
                                        !_manuallyEditedWeights.contains(
                                          setNumber,
                                        ) &&
                                        (_weightControllers[setNumber]
                                                ?.text
                                                .isNotEmpty ??
                                            false);
                                    if (isGhost) {
                                      _weightControllers[setNumber]!.selection =
                                          TextSelection(
                                            baseOffset: 0,
                                            extentOffset:
                                                _weightControllers[setNumber]!
                                                    .text
                                                    .length,
                                          );
                                    }
                                  },
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? CleanTheme.accentGreen
                                        : (!_manuallyEditedWeights.contains(
                                                    setNumber,
                                                  ) &&
                                                  _weightControllers[setNumber]!
                                                      .text
                                                      .isNotEmpty
                                              ? CleanTheme.textSecondary
                                                    .withValues(alpha: 0.5)
                                              : CleanTheme.textPrimary),
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    hintText: '0',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: CleanTheme.textTertiary,
                                    ),
                                  ),
                                  enabled: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Reps/Duration Column
                      Expanded(
                        flex: isCardioMobility ? 6 : 3,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCardioMobility
                                  ? 'OBIETTIVI: ${_presetReps[setNumber] ?? widget.exercise.reps}s'
                                  : 'OBIETTIVI: ${_presetReps[setNumber] ?? widget.exercise.reps}',
                              style: GoogleFonts.outfit(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: CleanTheme.textPrimary.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? CleanTheme.accentGreen.withValues(
                                        alpha: 0.06,
                                      )
                                    : CleanTheme.chromeSubtle.withValues(
                                        alpha: 0.5,
                                      ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isCompleted
                                      ? CleanTheme.accentGreen.withValues(
                                          alpha: 0.3,
                                        )
                                      : CleanTheme.borderSecondary,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: _repsControllers[setNumber],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onTap: () {
                                  final isGhost =
                                      !_manuallyEditedReps.contains(
                                        setNumber,
                                      ) &&
                                      (_repsControllers[setNumber]
                                              ?.text
                                              .isNotEmpty ??
                                          false);
                                  if (isGhost) {
                                    _repsControllers[setNumber]!
                                        .selection = TextSelection(
                                      baseOffset: 0,
                                      extentOffset: _repsControllers[setNumber]!
                                          .text
                                          .length,
                                    );
                                  }
                                },
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? CleanTheme.accentGreen
                                      : (!_manuallyEditedReps.contains(
                                                  setNumber,
                                                ) &&
                                                _repsControllers[setNumber]!
                                                    .text
                                                    .isNotEmpty
                                            ? CleanTheme.textSecondary
                                                  .withValues(alpha: 0.5)
                                            : CleanTheme.textPrimary),
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                  hintText: _presetReps[setNumber] ?? '10',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: CleanTheme.textTertiary,
                                  ),
                                ),
                                enabled: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // RPE Column (only for strength)
                      if (!isCardioMobility) ...[
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showRPEPicker(setNumber),
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _getRPEColor(_rpe[setNumber] ?? 7)
                                        .withValues(
                                          alpha: isCompleted ? 0.08 : 0.12,
                                        ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getRPEColor(
                                        _rpe[setNumber] ?? 7,
                                      ).withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${_rpe[setNumber] ?? 7}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _getRPEColor(
                                          _rpe[setNumber] ?? 7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Premium Animated Checkbox
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 14), // Offset for labels
                          _PremiumCheckbox(
                            isCompleted: isCompleted,
                            onTap: () {
                              if (!isCompleted) {
                                HapticService.mediumTap();
                                _successAudioPlayer.resume();
                                _successAudioPlayer.setSource(_successSource);
                              }
                              _toggleSet(setNumber, !isCompleted);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: (setNumber * 50).ms)
        .fade(duration: 400.ms)
        .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic)
        .animate(
          target: isCompleted ? 1 : 0,
        ) // Secondary animation triggered by completion
        .shimmer(
          duration: 800.ms,
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 4) return CleanTheme.accentGreen;
    if (rpe <= 6) return CleanTheme.accentGold;
    if (rpe <= 8) return CleanTheme.accentGold;
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(10, (index) {
                  final rpeValue = index + 1;
                  final isSelected = _rpe[setNumber] == rpeValue;
                  return GestureDetector(
                    onTap: () {
                      HapticService.selectionClick();
                      setState(() {
                        _rpe[setNumber] = rpeValue;
                      });
                      _scheduleAutoSave(setNumber);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getRPEColor(rpeValue)
                            : _getRPEColor(rpeValue).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? _getRPEColor(rpeValue)
                              : _getRPEColor(rpeValue).withValues(alpha: 0.4),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$rpeValue',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.black
                                : _getRPEColor(rpeValue),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
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
                    color: CleanTheme.accentGold,
                  ),
                ),
                Text(
                  '7-8: Difficile',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.accentGold,
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

    _scheduleAutoSave(setNumber);

    // Start rest timer IMMEDIATELY after checking the set for instant feedback
    if (value && setNumber <= widget.exercise.sets && !_isRestTimerActive) {
      // Sound is now handled in onTap for faster response
      _startRestTimer(setNumber);
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
    }

    // Keep workout session lifecycle in sync even if backend log wasn't ready.
    if (value) {
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

// ═══════════════════════════════════════════════════════════
// PREMIUM ANIMATED CHECKBOX
// ═══════════════════════════════════════════════════════════

class _PremiumCheckbox extends StatefulWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const _PremiumCheckbox({required this.isCompleted, required this.onTap});

  @override
  State<_PremiumCheckbox> createState() => _PremiumCheckboxState();
}

class _PremiumCheckboxState extends State<_PremiumCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _strokeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Spring scale: 0.85 → 1.18 → 1.0
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.18,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 3,
      ),
    ]).animate(_controller);

    // Checkmark stroke draw-in
    _strokeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

    // Glow fades in then out
    _glowAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 4,
      ),
    ]).animate(_controller);

    if (widget.isCompleted) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_PremiumCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward(from: 0);
    } else if (!widget.isCompleted && oldWidget.isCompleted) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glowOpacity = widget.isCompleted ? _glowAnim.value : 0.0;
          return Transform.scale(
            scale: widget.isCompleted ? _scaleAnim.value : 1.0,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? CleanTheme.accentGreen
                    : CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: widget.isCompleted
                      ? CleanTheme.accentGreen
                      : CleanTheme.chromeGray.withValues(alpha: 0.5),
                  width: widget.isCompleted ? 0 : 1.5,
                ),
                boxShadow: [
                  if (widget.isCompleted)
                    BoxShadow(
                      color: CleanTheme.accentGreen.withValues(
                        alpha: 0.45 * glowOpacity,
                      ),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _CheckmarkPainter(
                  progress: widget.isCompleted ? _strokeAnim.value : 0.0,
                  color: CleanTheme.textOnPrimary,
                  emptyColor: CleanTheme.chromeGray.withValues(alpha: 0.3),
                  isEmpty: !widget.isCompleted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 draw-in
  final Color color;
  final Color emptyColor;
  final bool isEmpty;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.emptyColor,
    required this.isEmpty,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isEmpty) {
      // Draw a subtle grey checkmark outline when uncompleted
      final paint = Paint()
        ..color = emptyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = _buildCheckPath(size);
      canvas.drawPath(path, paint);
      return;
    }

    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create path metrics to draw partial path
    final fullPath = _buildCheckPath(size);
    final metrics = fullPath.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final drawLength = totalLength * progress;

    double remaining = drawLength;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final segLen = math.min(remaining, metric.length);
      canvas.drawPath(metric.extractPath(0, segLen), paint);
      remaining -= segLen;
    }
  }

  Path _buildCheckPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    // Classic checkmark: bottom-left to center-bottom to top-right
    path.moveTo(w * 0.22, h * 0.50);
    path.lineTo(w * 0.42, h * 0.68);
    path.lineTo(w * 0.78, h * 0.32);
    return path;
  }

  @override
  bool shouldRepaint(_CheckmarkPainter old) =>
      old.progress != progress || old.isEmpty != isEmpty;
}
