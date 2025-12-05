import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/trial_workout_model.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/workout/immersive_workout_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// IMMERSIVE TRIAL WORKOUT SCREEN - Dark mode focused experience
/// ═══════════════════════════════════════════════════════════
class ImmersiveTrialWorkoutScreen extends StatefulWidget {
  final TrialWorkout trialWorkout;

  const ImmersiveTrialWorkoutScreen({super.key, required this.trialWorkout});

  @override
  State<ImmersiveTrialWorkoutScreen> createState() =>
      _ImmersiveTrialWorkoutScreenState();
}

class _ImmersiveTrialWorkoutScreenState
    extends State<ImmersiveTrialWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 0;
  bool _setStarted = false;
  bool _isResting = false;
  int _restSecondsRemaining = 60;
  final bool _isSubmitting = false;

  Timer? _workoutTimer;
  Timer? _restTimer;
  int _elapsedSeconds = 0;
  int _totalWorkoutSeconds = 0;

  final List<Map<String, dynamic>> _completedSets = [];

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startSet() {
    setState(() {
      _setStarted = true;
      _elapsedSeconds = 0;
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          _totalWorkoutSeconds++;
        });
      }
    });
  }

  void _completeSet() {
    _workoutTimer?.cancel();
    final currentExercise =
        widget.trialWorkout.exercises[_currentExerciseIndex];

    _completedSets.add({
      'exerciseIndex': _currentExerciseIndex,
      'setNumber': _currentSetNumber,
      'reps': currentExercise.reps,
      'duration': _elapsedSeconds,
    });

    setState(() => _setStarted = false);

    if (_currentSetNumber < currentExercise.sets - 1) {
      _startRest();
    } else if (_currentExerciseIndex <
        widget.trialWorkout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSetNumber = 0;
      });
    } else {
      _finishWorkout();
    }
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = 60;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _restSecondsRemaining--);
        if (_restSecondsRemaining <= 0) _endRest();
      }
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _currentSetNumber++;
    });
  }

  void _finishWorkout() {
    // Show completion dialog and return to previous screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.immersiveDarkSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('🎉', style: TextStyle(fontSize: 48))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Workout Completato!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tempo totale: ${_totalWorkoutSeconds ~/ 60}:${(_totalWorkoutSeconds % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Continua',
              style: GoogleFonts.inter(
                color: CleanTheme.immersiveAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _parseReps(String reps) {
    final match = RegExp(r'\d+').firstMatch(reps);
    return match != null ? int.parse(match.group(0)!) : 10;
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return ImmersiveWorkoutScaffold(
        showProgress: false,
        child: const Center(
          child: CircularProgressIndicator(color: CleanTheme.immersiveAccent),
        ),
      );
    }

    final currentExercise =
        widget.trialWorkout.exercises[_currentExerciseIndex];
    final progress =
        (_currentExerciseIndex + 1) / widget.trialWorkout.exercises.length;

    if (_isResting) {
      return ImmersiveWorkoutScaffold(
        progressValue: progress,
        child: ImmersiveRestTimer(
          secondsRemaining: _restSecondsRemaining,
          totalSeconds: 60,
          onSkip: _endRest,
        ),
      );
    }

    return ImmersiveWorkoutScaffold(
      progressValue: progress,
      onBack: _showExitConfirmation,
      child: Column(
        children: [
          const Spacer(flex: 1),
          ImmersiveExerciseCard(
            exerciseName: currentExercise.name,
            currentSet: _currentSetNumber + 1,
            totalSets: currentExercise.sets,
            targetReps: _parseReps(currentExercise.reps),
            notes: currentExercise.notes,
          ),
          const Spacer(flex: 1),
          if (_setStarted)
            ImmersiveTimer(time: _formattedTime, label: 'Tempo serie'),
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _setStarted
                ? ImmersiveActionButton(
                    text: 'SERIE COMPLETATA',
                    icon: Icons.check_circle,
                    onPressed: _completeSet,
                  )
                : ImmersiveActionButton(
                    text: 'INIZIA SERIE ${_currentSetNumber + 1}',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _startSet,
                  ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.immersiveDarkSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Uscire dal workout?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Il tuo progresso non verrà salvato.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continua',
              style: GoogleFonts.inter(color: CleanTheme.immersiveAccent),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Esci',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}
