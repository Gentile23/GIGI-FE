import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

enum _EditableSetField { weight, reps, rpe }

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

  /// Runtime set controls shown in the set table header.
  final Future<void> Function()? onAddSet;
  final Future<void> Function()? onRemoveSet;

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
    this.onAddSet,
    this.onRemoveSet,
    this.isTrial = false,
    this.debounceTime = const Duration(milliseconds: 500),
  });

  @override
  State<SetLoggingWidget> createState() => SetLoggingWidgetState();
}

class SetLoggingWidgetState extends State<SetLoggingWidget> {
  int get totalSets => widget.exercise.sets;

  _EditableSetField? _activeField;
  int? _activeFieldSetNumber;

  // --- Public methods to access controllers from overlay ---
  TextEditingController? getWeightController(int setNumber) =>
      _weightControllers[setNumber];
  TextEditingController? getRepsController(int setNumber) =>
      _repsControllers[setNumber];
  int getRpe(int setNumber) => _rpe[setNumber] ?? 7;

  int getPendingSetsCount() {
    int pending = 0;
    for (int setNumber = 1; setNumber <= totalSets; setNumber++) {
      if (!(_completedSets[setNumber] ?? false)) {
        pending++;
      }
    }
    return pending;
  }

  List<SetCompletionData> getCompletedSetEntries() {
    final entries = <SetCompletionData>[];
    for (int setNumber = 1; setNumber <= totalSets; setNumber++) {
      if (!(_completedSets[setNumber] ?? false)) continue;
      entries.add(
        SetCompletionData(
          setNumber: setNumber,
          weightKg: _weights[setNumber],
          reps: _reps[setNumber],
          rpe: _rpe[setNumber],
          previousWeightKg: null,
          isLastSet: setNumber == totalSets,
        ),
      );
    }
    return entries;
  }

  Future<bool> removeLastSet() async {
    if (totalSets <= 1) return false;

    final setNumber = totalSets;
    final existingLog = widget.exerciseLog?.setLogs.firstWhere(
      (s) => s.setNumber == setNumber,
      orElse: () => SetLogModel(
        id: '',
        exerciseLogId: '',
        setNumber: setNumber,
        reps: 0,
        completed: false,
      ),
    );

    if (!widget.isTrial && existingLog != null && existingLog.id.isNotEmpty) {
      await context.read<WorkoutLogProvider>().deleteSetLog(
        setLogId: existingLog.id,
        exerciseLogId: existingLog.exerciseLogId,
      );
    }

    if (_restTimerService?.state.isActive == true &&
        _restTimerService?.state.exerciseId == widget.restTimerId &&
        _restTimerService?.state.workoutDayId == widget.workoutDayId &&
        _restTimerService?.state.setNumber == setNumber) {
      await _stopRestTimer();
    }

    _removeRuntimeSetState(setNumber);
    _notifyCompletionChanged();
    return true;
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
  final Map<int, FocusNode> _weightFocusNodes = {};
  final Map<int, FocusNode> _repsFocusNodes = {};
  OverlayEntry? _keyboardAccessoryEntry;
  int? _activeInputSetNumber;

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

  int _getRestSecondsForSet(int setNumber) {
    final perSet = widget.exercise.restSecondsPerSet;
    if (perSet == null || perSet.isEmpty) {
      return _defaultRestSeconds;
    }

    final index = (setNumber - 1).clamp(0, perSet.length - 1);
    final candidate = perSet[index];
    if (candidate < 0) return _defaultRestSeconds;
    return candidate;
  }

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

  int? _parseIntFlexible(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.round();
    }
    return null;
  }

  int _resolveDefaultRepsForSet(int setNumber) {
    final preset = _presetReps[setNumber] ?? '';
    final parsed = _parseIntFlexible(preset);
    if (parsed != null && parsed > 0) return parsed;
    return _reps[setNumber] != null && (_reps[setNumber] ?? 0) > 0
        ? _reps[setNumber]!
        : 10;
  }

  void _ensureDefaultsForSet(int setNumber) {
    final currentReps = _reps[setNumber] ?? 0;
    if (currentReps <= 0) {
      _reps[setNumber] = _resolveDefaultRepsForSet(setNumber);
      final controller = _repsControllers[setNumber];
      if (controller != null) {
        controller.value = TextEditingValue(
          text: _reps[setNumber]!.toString(),
          selection: TextSelection.collapsed(
            offset: _reps[setNumber]!.toString().length,
          ),
        );
      }
    }

    final currentRpe = _rpe[setNumber] ?? 0;
    if (currentRpe <= 0) {
      _rpe[setNumber] = 7;
    }
  }

  Future<void> completeAllSetsQuick() async {
    final pendingSets = <int>[];
    for (int setNumber = 1; setNumber <= totalSets; setNumber++) {
      if (!(_completedSets[setNumber] ?? false)) {
        pendingSets.add(setNumber);
      }
    }
    if (pendingSets.isEmpty) return;

    // --- OPTIMISTIC UI START ---
    // 1. Instantly update all checkboxes and set defaults
    setState(() {
      for (final setNumber in pendingSets) {
        _ensureDefaultsForSet(setNumber);
        _completedSets[setNumber] = true;
      }
      _isRestTimerActive = false;
    });

    // 2. Play a single success sound & haptic
    unawaited(_successAudioPlayer.resume());
    HapticService.mediumTap();

    // 3. Stop rest timer globally
    if (_restTimerService?.state.isActive == true) {
      unawaited(_stopRestTimer());
    }

    // 4. Notify parent immediately
    _notifyCompletionChanged();
    // --- OPTIMISTIC UI END ---

    if (widget.isTrial) return;

    try {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      String? exerciseLogId = widget.exerciseLog?.id;

      // Ensure exercise log exists
      if (exerciseLogId == null) {
        final newLog = await provider.addExerciseLog(
          exerciseId: widget.exercise.exercise.id,
          orderIndex: 0, // Parent should ideally provide correct index
          exerciseType: widget.exercise.exerciseType,
        );
        exerciseLogId = newLog?.id;
      }

      if (exerciseLogId != null) {
        final bulkData = pendingSets.map((setNumber) {
          return {
            'set_number': setNumber,
            'reps': _reps[setNumber] ?? 0,
            'weight_kg': _weights[setNumber],
            'rpe': _rpe[setNumber],
            'completed': true,
          };
        }).toList();

        await provider.addBulkSets(
          exerciseLogId: exerciseLogId,
          sets: bulkData,
        );
      }
    } catch (e) {
      debugPrint('🚨 Bulk completion sync failed: $e');
      // We keep the optimistic state unless it's a structural error
    }
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
    if (widget.exercise.sets != oldWidget.exercise.sets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncRuntimeSetCount(oldWidget.exercise.sets, widget.exercise.sets);
      });
    }
    // If the exercise log has been updated from outside (e.g. backend refresh)
    // and we are not currently editing, sync local state.
    if (widget.exerciseLog != oldWidget.exerciseLog &&
        widget.exerciseLog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncStateWithLog();
      });
    }
  }

  void _syncRuntimeSetCount(int oldCount, int newCount) {
    if (newCount == oldCount) return;

    if (newCount > oldCount) {
      for (int setNumber = oldCount + 1; setNumber <= newCount; setNumber++) {
        _appendRuntimeSetState(setNumber);
      }
      _notifyCompletionChanged();
      return;
    }

    for (int setNumber = oldCount; setNumber > newCount; setNumber--) {
      _removeRuntimeSetState(setNumber);
    }
    _notifyCompletionChanged();
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
      _setStateSafely(() {
        _isRestTimerActive = true;
      });
      return;
    }

    if (_isRestTimerActive && isThisTimer) {
      _setStateSafely(() {
        _isRestTimerActive = false;
      });
    }
  }

  void _setStateSafely(VoidCallback fn) {
    if (!mounted) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuildingFrame =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (isBuildingFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
      return;
    }

    setState(fn);
  }

  void _appendRuntimeSetState(int setNumber) {
    final sourceSetNumber = math.max(1, setNumber - 1);
    final inheritedWeight = _weights[sourceSetNumber];
    final inheritedReps =
        _reps[sourceSetNumber] ??
        _parseIntFlexible(_presetReps[sourceSetNumber]) ??
        0;
    final inheritedRpe = _rpe[sourceSetNumber] ?? 7;
    final inheritedPreset = _presetReps[sourceSetNumber] ?? '10';

    _weights[setNumber] = inheritedWeight ?? 0;
    _reps[setNumber] = inheritedReps;
    _rpe[setNumber] = inheritedRpe;
    _completedSets[setNumber] = false;
    _presetReps[setNumber] = inheritedPreset;

    final weightController = TextEditingController(
      text: inheritedWeight != null && inheritedWeight > 0
          ? _formatWeightForInput(inheritedWeight)
          : '',
    );
    weightController.addListener(() {
      final text = weightController.text;
      final parsed = _parseWeightInput(text);

      if (parsed != null && parsed > 0 && parsed != _weights[setNumber]) {
        setState(() {
          _weights[setNumber] = parsed;
          _handleWeightChange(setNumber, parsed);
        });
      } else if (text == '0' && _weights[setNumber] != 0) {
        setState(() {
          _weights[setNumber] = 0;
          _handleWeightChange(setNumber, 0);
        });
      }
    });
    _weightControllers[setNumber] = weightController;
    _weightFocusNodes[setNumber] = _createInputFocusNode(
      setNumber,
      _EditableSetField.weight,
    );

    final repsController = TextEditingController(
      text: inheritedReps > 0 ? inheritedReps.toString() : '',
    );
    repsController.addListener(() {
      final text = repsController.text;
      final parsed = int.tryParse(text);
      if (parsed != null && parsed != _reps[setNumber]) {
        setState(() {
          _reps[setNumber] = parsed;
          _manuallyEditedReps.add(setNumber);
        });
        _scheduleAutoSave(setNumber);
      } else if (text.isEmpty && _reps[setNumber] != 0) {
        setState(() {
          _reps[setNumber] = 0;
          _manuallyEditedReps.add(setNumber);
        });
        _scheduleAutoSave(setNumber);
      }
    });
    _repsControllers[setNumber] = repsController;
    _repsFocusNodes[setNumber] = _createInputFocusNode(
      setNumber,
      _EditableSetField.reps,
    );
  }

  void _removeRuntimeSetState(int setNumber) {
    _weights.remove(setNumber);
    _reps.remove(setNumber);
    _rpe.remove(setNumber);
    _completedSets.remove(setNumber);
    _presetReps.remove(setNumber);
    _manuallyEditedWeights.remove(setNumber);
    _manuallyEditedReps.remove(setNumber);
    _autoSaveTimers.remove(setNumber)?.cancel();
    _weightControllers.remove(setNumber)?.dispose();
    _repsControllers.remove(setNumber)?.dispose();
    _weightFocusNodes.remove(setNumber)?.dispose();
    _repsFocusNodes.remove(setNumber)?.dispose();
  }

  void _notifyCompletionChanged() {
    final allCompleted = List.generate(
      totalSets,
      (index) => index + 1,
    ).every((setNumber) => _completedSets[setNumber] == true);
    widget.onCompletionChanged(allCompleted);
  }

  void _syncStateWithLog() {
    if (widget.exerciseLog == null) return;

    _setStateSafely(() {
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
    for (int i = 1; i <= totalSets; i++) {
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
      _weightFocusNodes[i] = _createInputFocusNode(i, _EditableSetField.weight);

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
      _repsFocusNodes[i] = _createInputFocusNode(i, _EditableSetField.reps);
    }
  }

  FocusNode _createInputFocusNode(int setNumber, _EditableSetField field) {
    final node = FocusNode(debugLabel: 'set_logging_input_$setNumber');
    node.addListener(() => _handleInputFocusChange(setNumber, field));
    return node;
  }

  void _handleInputFocusChange(int setNumber, _EditableSetField field) {
    final hasFocusedInput =
        _weightFocusNodes[setNumber]?.hasFocus == true ||
        _repsFocusNodes[setNumber]?.hasFocus == true;

    if (hasFocusedInput) {
      _activeInputSetNumber = setNumber;
      _setActiveField(setNumber, field);
      _showKeyboardAccessory();
      return;
    }

    if (_hasAnyActiveInputFocus()) {
      _keyboardAccessoryEntry?.markNeedsBuild();
      return;
    }

    _activeInputSetNumber = null;
    if (_activeField == field && _activeFieldSetNumber == setNumber) {
      _clearActiveField();
    }
    _removeKeyboardAccessory();
  }

  void _setActiveField(int setNumber, _EditableSetField field) {
    if (_activeFieldSetNumber == setNumber && _activeField == field) return;
    setState(() {
      _activeFieldSetNumber = setNumber;
      _activeField = field;
    });
  }

  void _clearActiveField() {
    if (_activeField == null && _activeFieldSetNumber == null) return;
    setState(() {
      _activeField = null;
      _activeFieldSetNumber = null;
    });
  }

  bool _isFieldActive(int setNumber, _EditableSetField field) {
    return _activeFieldSetNumber == setNumber && _activeField == field;
  }

  bool _hasAnyActiveInputFocus() {
    return _weightFocusNodes.values.any((node) => node.hasFocus) ||
        _repsFocusNodes.values.any((node) => node.hasFocus);
  }

  void _showKeyboardAccessory() {
    if (!mounted) return;

    if (_keyboardAccessoryEntry == null) {
      _keyboardAccessoryEntry = OverlayEntry(
        builder: (overlayContext) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          if (!_hasAnyActiveInputFocus() || bottomInset <= 0) {
            return const SizedBox.shrink();
          }

          return Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CleanTheme.surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: CleanTheme.borderSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _dismissKeyboardAndSave,
                      child: Text(
                        'Salva',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      Overlay.of(context, rootOverlay: true).insert(_keyboardAccessoryEntry!);
      return;
    }

    _keyboardAccessoryEntry?.markNeedsBuild();
  }

  void _removeKeyboardAccessory() {
    _keyboardAccessoryEntry?.remove();
    _keyboardAccessoryEntry = null;
  }

  Future<void> _dismissKeyboardAndSave() async {
    final setNumber = _activeInputSetNumber;
    if (setNumber != null) {
      _autoSaveTimers[setNumber]?.cancel();
      await _persistSetData(setNumber);
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // Map to track manual overrides to auto-fill
  final Set<int> _manuallyEditedWeights = {};
  final Set<int> _manuallyEditedReps = {};

  // Map for debounce timers
  final Map<int, Timer?> _autoSaveTimers = {};

  void _handleWeightChange(int setNumber, double weight) {
    _manuallyEditedWeights.add(setNumber);

    // Auto-fill subsequent sets that haven't been manually edited
    for (int i = setNumber + 1; i <= totalSets; i++) {
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
    // Legacy in-card coaching controls disabled.
    // Guided execution now managed by session-level controller only.
    _showCoachingControls = false;
  }

  void _initializeData() {
    final repsList = widget.exercise.reps
        .split(',')
        .map((s) => s.trim())
        .toList();

    for (int i = 1; i <= totalSets; i++) {
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

        // PERSISTENCE FIX: Load data even if ID is empty (local state)
        if (setLog.id.isNotEmpty ||
            setLog.completed ||
            (setLog.weightKg ?? 0) > 0) {
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
          final parsedSetNumber = _parseIntFlexible(set['set_number']);
          if (parsedSetNumber == null || parsedSetNumber <= 0) {
            continue;
          }

          // Safely parse weight_kg which may come as String or num from API
          dynamic weightValue = set['weight_kg'];
          double? parsedWeight;
          if (weightValue is num) {
            parsedWeight = weightValue.toDouble();
          } else if (weightValue is String) {
            parsedWeight = _parseWeightInput(weightValue);
          }

          previousMap[parsedSetNumber] = {
            'reps': _parseIntFlexible(set['reps']),
            'weight_kg': parsedWeight,
            'rpe': _parseIntFlexible(set['rpe']),
          };
        }

        if (mounted) {
          setState(() {
            _previousData = previousMap;
            // Auto-populate weight & reps controllers with previous data if current is empty
            for (var entry in previousMap.entries) {
              final setNum = entry.key;
              final prevWeight = entry.value['weight_kg'];
              final prevReps = _parseIntFlexible(entry.value['reps']);

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
    for (final node in _weightFocusNodes.values) {
      node.dispose();
    }
    for (final node in _repsFocusNodes.values) {
      node.dispose();
    }
    _removeKeyboardAccessory();
    _restTimerService?.removeListener(_handleRestTimerServiceChanged);
    _coachingPlayer.dispose();
    _successAudioPlayer.dispose();
    for (final timer in _autoSaveTimers.values) {
      if (timer?.isActive ?? false) {
        // No need to cancel, just fire the persistence
      }
      timer?.cancel();
    }
    super.dispose();
  }

  Future<void> _startRestTimer(int setNumber) async {
    final restSeconds = _getRestSecondsForSet(setNumber);
    if (restSeconds <= 0) {
      return;
    }

    setState(() {
      _isRestTimerActive = true;
    });

    await context.read<RestTimerService>().start(
      workoutDayId: widget.workoutDayId,
      exerciseId: widget.restTimerId,
      setNumber: setNumber,
      totalSeconds: restSeconds,
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

          // In-card coaching controls disabled (single global control plane).

          // Rest Timer is now rendered fullscreen by parent via onRestTimerStateChanged
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
            child: Row(
              children: [
                Text(
                  'Serie',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: CleanTheme.chromeSubtle.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CleanTheme.chromeGray.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SetCountButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Rimuovi ultima serie',
                        color: CleanTheme.accentRed,
                        onTap: totalSets > 1 && widget.onRemoveSet != null
                            ? () async {
                                await widget.onRemoveSet!.call();
                              }
                            : null,
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '$totalSets',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ),
                      _SetCountButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Aggiungi serie',
                        color: CleanTheme.primaryColor,
                        onTap: totalSets < 20 && widget.onAddSet != null
                            ? () async {
                                await widget.onAddSet!.call();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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

          ...List.generate(totalSets, (index) {
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
    final isWeightActive = _isFieldActive(setNumber, _EditableSetField.weight);
    final isRepsActive = _isFieldActive(setNumber, _EditableSetField.reps);
    final isRpeActive = _isFieldActive(setNumber, _EditableSetField.rpe);

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
                              SizedBox(
                                height: 46,
                                child: DecoratedBox(
                                  decoration: _fieldDecoration(
                                    isCompleted: isCompleted,
                                    isActive: isWeightActive,
                                  ),
                                  child: _buildInputSelectionTheme(
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      controller: _weightControllers[setNumber],
                                      focusNode: _weightFocusNodes[setNumber],
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textInputAction: TextInputAction.done,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*([,.]\d*)?$'),
                                        ),
                                      ],
                                      onSubmitted: (_) =>
                                          _dismissKeyboardAndSave(),
                                      scrollPadding: const EdgeInsets.only(
                                        bottom: 120,
                                      ),
                                      onTap: () {
                                        _setActiveField(
                                          setNumber,
                                          _EditableSetField.weight,
                                        );
                                        final isGhost =
                                            !_manuallyEditedWeights.contains(
                                              setNumber,
                                            ) &&
                                            (_weightControllers[setNumber]
                                                    ?.text
                                                    .isNotEmpty ??
                                                false);
                                        if (isGhost) {
                                          _weightControllers[setNumber]!
                                              .selection = TextSelection(
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
                                        color: CleanTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 13,
                                              horizontal: 4,
                                            ),
                                        hintText: '0',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: CleanTheme.textTertiary,
                                        ),
                                      ),
                                      enabled: true,
                                      cursorColor: CleanTheme.textPrimary,
                                    ),
                                  ),
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
                            Container(
                              constraints: const BoxConstraints(minHeight: 54),
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                              decoration: _fieldDecoration(
                                isCompleted: isCompleted,
                                isActive: isRepsActive,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isCardioMobility
                                        ? 'Target ${_presetReps[setNumber] ?? widget.exercise.reps}s'
                                        : 'Target ${_presetReps[setNumber] ?? widget.exercise.reps}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 8.5,
                                      height: 1,
                                      fontWeight: FontWeight.w800,
                                      color: isRepsActive
                                          ? CleanTheme.textPrimary
                                          : CleanTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    height: 30,
                                    child: _buildInputSelectionTheme(
                                      child: TextField(
                                        textAlign: TextAlign.center,
                                        controller: _repsControllers[setNumber],
                                        focusNode: _repsFocusNodes[setNumber],
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.done,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onSubmitted: (_) =>
                                            _dismissKeyboardAndSave(),
                                        onTap: () {
                                          _setActiveField(
                                            setNumber,
                                            _EditableSetField.reps,
                                          );
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
                                              extentOffset:
                                                  _repsControllers[setNumber]!
                                                      .text
                                                      .length,
                                            );
                                          }
                                        },
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: CleanTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 6,
                                                horizontal: 4,
                                              ),
                                          hintText:
                                              _presetReps[setNumber] ?? '10',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: CleanTheme.textTertiary,
                                          ),
                                        ),
                                        enabled: true,
                                        cursorColor: CleanTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isRpeActive
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: isRpeActive
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getRPEColor(_rpe[setNumber] ?? 7)
                                          .withValues(
                                            alpha: isCompleted ? 0.08 : 0.12,
                                          ),
                                      border: Border.all(
                                        color: _getRPEColor(
                                          _rpe[setNumber] ?? 7,
                                        ).withValues(alpha: 0.35),
                                        width: isRpeActive ? 1.4 : 1,
                                      ),
                                      boxShadow: isRpeActive
                                          ? [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.55,
                                                ),
                                                blurRadius: 14,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_rpe[setNumber] ?? 7}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: CleanTheme.textPrimary,
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

  BoxDecoration _fieldDecoration({
    required bool isCompleted,
    required bool isActive,
  }) {
    return BoxDecoration(
      color: isCompleted
          ? CleanTheme.accentGreen.withValues(alpha: 0.06)
          : isActive
          ? Colors.white
          : CleanTheme.chromeSubtle.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isCompleted
            ? CleanTheme.accentGreen.withValues(alpha: 0.3)
            : isActive
            ? Colors.white
            : CleanTheme.borderSecondary,
        width: isActive ? 1.4 : 1,
      ),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );
  }

  Widget _buildInputSelectionTheme({required Widget child}) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: CleanTheme.textPrimary,
          selectionColor: Color(0x66FFFFFF),
          selectionHandleColor: Colors.white,
        ),
      ),
      child: child,
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 4) return CleanTheme.accentGreen;
    if (rpe <= 6) return CleanTheme.accentGold;
    if (rpe <= 8) return CleanTheme.accentGold;
    return CleanTheme.accentRed;
  }

  void _showRPEPicker(int setNumber) {
    _setActiveField(setNumber, _EditableSetField.rpe);
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
    ).whenComplete(() {
      if (!_hasAnyActiveInputFocus() &&
          _activeFieldSetNumber == setNumber &&
          _activeField == _EditableSetField.rpe) {
        _clearActiveField();
      }
    });
  }

  Future<void> _toggleSet(
    int setNumber,
    bool? value, {
    bool skipRestTimer = false,
  }) async {
    if (value == null) return;

    setState(() {
      _completedSets[setNumber] = value;
    });

    // PERSISTENCE FIX: For checkmarks/toggles, we persist IMMEDIATELY
    // instead of scheduling a debounce timer to avoid state loss on scroll.
    _persistSetData(setNumber);

    // Start rest timer IMMEDIATELY after checking the set for instant feedback
    if (!skipRestTimer &&
        value &&
        setNumber <= totalSets &&
        !_isRestTimerActive) {
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
            isLastSet: setNumber == totalSets,
          ),
        );
      }

      // Update completion status
      _notifyCompletionChanged();

      if (List.generate(totalSets, (index) => index + 1).every(
            (currentSetNumber) => _completedSets[currentSetNumber] == true,
          ) &&
          _showCoachingControls) {
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
          isLastSet: setNumber == totalSets,
        ),
      );
    }

    final allCompleted = List.generate(
      totalSets,
      (index) => index + 1,
    ).every((currentSetNumber) => _completedSets[currentSetNumber] == true);
    _notifyCompletionChanged();

    if (allCompleted && _showCoachingControls) {
      _stopRestTimer(); // Stop timer if all sets complete
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _coachingPlayer.playPostExercise();
        }
      });
    }
  }

  // ignore: unused_element
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

class _SetCountButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Future<void> Function()? onTap;

  const _SetCountButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final effectiveColor = isEnabled ? color : CleanTheme.textTertiary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 32,
          height: 34,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: isEnabled ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: effectiveColor.withValues(alpha: isEnabled ? 0.35 : 0.18),
            ),
          ),
          child: Icon(icon, size: 19, color: effectiveColor),
        ),
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
