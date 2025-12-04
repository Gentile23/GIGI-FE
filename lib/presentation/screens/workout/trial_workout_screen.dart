import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/trial_workout_model.dart';
import '../../../data/models/voice_coaching_model.dart';
import '../../../data/services/trial_workout_service.dart';
import '../../../data/services/voice_coaching_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';
import '../../widgets/voice_coaching_player.dart';
import 'trial_completion_screen.dart';
import 'post_trial_assessment_screen.dart';

class TrialWorkoutScreen extends StatefulWidget {
  final TrialWorkout trialWorkout;

  const TrialWorkoutScreen({super.key, required this.trialWorkout});

  @override
  State<TrialWorkoutScreen> createState() => _TrialWorkoutScreenState();
}

class _TrialWorkoutScreenState extends State<TrialWorkoutScreen> {
  final Map<String, int> _difficultyRatings = {};
  final List<String> _skippedExercises = [];
  final List<String> _formIssues = [];
  int _currentExerciseIndex = 0;
  int _totalRestTime = 0;
  int _overallFatigue = 3;
  bool _isSubmitting = false;

  // Per-set tracking
  bool _setStarted = false;
  int _currentSetNumber = 0; // 0-indexed
  final Map<String, List<int>> _actualRepsPerformed = {};
  final Map<String, List<double>> _weightsUsed = {};

  late final TrialWorkoutService _trialService;
  late final VoiceCoachingService _voiceCoachingService;
  VoiceCoaching? _currentVoiceCoaching;
  bool _isLoadingVoiceCoaching = false;
  final VoiceCoachingController _voiceCoachingController =
      VoiceCoachingController();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _trialService = TrialWorkoutService(apiClient);
    _voiceCoachingService = VoiceCoachingService(apiClient);
  }

  // Timer logic
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = '00:00';

  // Countdown logic
  bool _isCountdownActive = false;
  int _countdownSeconds = 3;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final int totalSeconds = _stopwatch.elapsed.inSeconds;
          final int minutes = totalSeconds ~/ 60;
          final int seconds = totalSeconds % 60;
          _formattedTime =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  Future<void> _loadVoiceCoaching() async {
    final exercise = widget.trialWorkout.exercises[_currentExerciseIndex];

    // Check if we already have voice coaching URLs (from trial template)
    if (exercise.voiceCoachingPreUrl != null ||
        exercise.voiceCoachingDuringUrl != null ||
        exercise.voiceCoachingPostUrl != null) {
      setState(() {
        _isLoadingVoiceCoaching = false;
        _currentVoiceCoaching = VoiceCoaching(
          exerciseId: exercise.id ?? '',
          multiPhase: MultiPhaseCoaching(
            preExercise: CoachingPhase(
              audioUrl: exercise.voiceCoachingPreUrl,
              duration: 10, // Default 10 seconds for pre-exercise
            ),
            duringExecution: CoachingPhase(
              audioUrl: exercise.voiceCoachingDuringUrl,
            ),
            postExercise: CoachingPhase(
              audioUrl: exercise.voiceCoachingPostUrl,
            ),
          ),
        );
      });
      return;
    }

    // Only load if we have an ID (meaning it's a real exercise in DB)
    if (exercise.id != null) {
      setState(() {
        _isLoadingVoiceCoaching = true;
      });

      try {
        final voiceCoaching = await _voiceCoachingService.generateVoiceCoaching(
          exercise.id!,
          isTrial: true,
          sets: exercise.sets,
          reps: int.tryParse(exercise.reps.split(' ').first) ?? 10,
          structured: true,
        );

        if (mounted) {
          setState(() {
            _currentVoiceCoaching = voiceCoaching;
            _isLoadingVoiceCoaching = false;
          });
        }
      } catch (e) {
        print('Error loading voice coaching: $e');
        if (mounted) {
          setState(() {
            _isLoadingVoiceCoaching = false;
          });
        }
      }
    }
  }

  Future<void> _startSet() async {
    // Load voice coaching on first set
    if (_currentSetNumber == 0 && _currentVoiceCoaching == null) {
      await _loadVoiceCoaching();
    }

    // 1. Play pre-exercise audio immediately
    _voiceCoachingController.playPre();

    // 2. Determine countdown duration from voice coaching or use default
    int countdownDuration = 3;
    if (_currentVoiceCoaching?.multiPhase?.preExercise?.duration != null) {
      countdownDuration =
          _currentVoiceCoaching!.multiPhase!.preExercise!.duration!;
    }

    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = countdownDuration;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 1) {
            _countdownSeconds--;
          } else {
            _countdownTimer?.cancel();
            _isCountdownActive = false;
            _setStarted = true;
            _startTimer();

            // 3. Start "during" audio after a short delay (2 seconds into exercise)
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _setStarted) {
                _voiceCoachingController.playDuring();
              }
            });
          }
        });
      }
    });
  }

  void _showSetCompletionDialog(TrialExercise exercise) {
    _stopTimer();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    bool isBodyweight = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: ModernTheme.cardColor,
          title: Text(
            'Serie ${_currentSetNumber + 1}/${exercise.sets} completata!',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tempo: $_formattedTime',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quante ripetizioni hai fatto?',
                    hintText: 'Es: 10',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Esercizio a corpo libero'),
                  value: isBodyweight,
                  onChanged: (value) => setState(() => isBodyweight = value),
                  activeColor: ModernTheme.accentColor,
                ),
                if (!isBodyweight) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Peso utilizzato (kg)',
                      hintText: 'Es: 20.5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ModernButton(
              text: 'Conferma',
              onPressed: () {
                final reps = int.tryParse(repsController.text) ?? 0;
                final weight = !isBodyweight
                    ? double.tryParse(weightController.text)
                    : null;

                Navigator.pop(context);
                _completeSet(reps, weight: weight);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _completeSet(int reps, {double? weight}) {
    final exercise = widget.trialWorkout.exercises[_currentExerciseIndex];

    // 4. Play post-exercise audio immediately when set is completed
    _voiceCoachingController.playPost();

    if (!_actualRepsPerformed.containsKey(exercise.name)) {
      _actualRepsPerformed[exercise.name] = [];
      _weightsUsed[exercise.name] = [];
    }

    _actualRepsPerformed[exercise.name]!.add(reps);
    if (weight != null) {
      _weightsUsed[exercise.name]!.add(weight);
    }

    setState(() {
      _currentSetNumber++;
      _setStarted = false;
      _formattedTime = '00:00';
    });

    // Check if all sets for this exercise are completed
    if (_currentSetNumber >= exercise.sets) {
      _showDifficultyDialog();
    }
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.cardColor,
        title: const Text('Quanto è stato difficile?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final difficulty = index + 1;
            return ListTile(
              title: Text(_getDifficultyLabel(difficulty)),
              leading: Text(
                _getDifficultyEmoji(difficulty),
                style: const TextStyle(fontSize: 24),
              ),
              onTap: () {
                Navigator.pop(context);
                _rateExercise(difficulty);
              },
            );
          }),
        ),
      ),
    );
  }

  void _rateExercise(int difficulty) {
    final exercise = widget.trialWorkout.exercises[_currentExerciseIndex];
    setState(() {
      _difficultyRatings[exercise.name] = difficulty;
      _setStarted = false;
      _currentSetNumber = 0; // Reset for next exercise
      _formattedTime = '00:00';
    });

    if (_currentExerciseIndex < widget.trialWorkout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentVoiceCoaching = null;
      });
    } else {
      _showFatigueDialog();
    }
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Molto facile';
      case 2:
        return 'Facile';
      case 3:
        return 'Moderato';
      case 4:
        return 'Impegnativo';
      case 5:
        return 'Molto difficile';
      default:
        return '';
    }
  }

  String _getDifficultyEmoji(int difficulty) {
    switch (difficulty) {
      case 1:
        return '😊';
      case 2:
        return '🙂';
      case 3:
        return '😐';
      case 4:
        return '😓';
      case 5:
        return '😰';
      default:
        return '';
    }
  }

  void _showFatigueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.cardColor,
        title: const Text('Livello di Fatica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Come ti senti dopo questo allenamento?'),
            const SizedBox(height: 24),
            ...List.generate(5, (index) {
              final level = index + 1;
              return RadioListTile<int>(
                title: Text(_getFatigueLabel(level)),
                value: level,
                groupValue: _overallFatigue,
                onChanged: (value) {
                  setState(() => _overallFatigue = value!);
                },
                activeColor: ModernTheme.accentColor,
              );
            }),
          ],
        ),
        actions: [
          ModernButton(text: 'Completa Trial', onPressed: _submitTrial),
        ],
      ),
    );
  }

  String _getFatigueLabel(int level) {
    switch (level) {
      case 1:
        return '😊 Molto facile';
      case 2:
        return '🙂 Facile';
      case 3:
        return '😐 Moderato';
      case 4:
        return '😓 Impegnativo';
      case 5:
        return '😰 Molto difficile';
      default:
        return '';
    }
  }

  Future<void> _submitTrial() async {
    Navigator.pop(context); // Close fatigue dialog

    // Navigate to post-assessment screen
    final assessmentData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const PostTrialAssessmentScreen(),
      ),
    );

    if (assessmentData == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final performanceData = TrialPerformanceData(
      difficultyRatings: _difficultyRatings,
      skippedExercises: _skippedExercises,
      totalRestTime: _totalRestTime,
      overallFatigue: _overallFatigue,
      formIssues: _formIssues,
      actualRepsPerformed: _actualRepsPerformed,
      weightsUsed: _weightsUsed,
      feedback: assessmentData['additional_notes'] as String?,
    );

    try {
      final response = await _trialService.submitTrialResults(performanceData);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (response != null) {
          // Navigate to completion screen or show success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TrialCompletionScreen(completionResponse: response),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'invio dei risultati. Riprova.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore imprevisto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: ModernTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentExercise =
        widget.trialWorkout.exercises[_currentExerciseIndex];
    final progress =
        (_currentExerciseIndex + 1) / widget.trialWorkout.exercises.length;

    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Trial Workout'),
        backgroundColor: ModernTheme.cardColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ModernTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentExerciseIndex + 1}/${widget.trialWorkout.exercises.length}',
                  style: TextStyle(
                    color: ModernTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.accentColor),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentExerciseIndex == 0 && _currentSetNumber == 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ModernTheme.accentColor.withOpacity(0.2),
                            Colors.purple.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ModernTheme.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: ModernTheme.accentColor,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎤 Voice Coaching GRATIS',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: ModernTheme.accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prova il coach vocale durante questo trial!',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentExercise.name,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ModernTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Serie ${_currentSetNumber + 1}/${currentExercise.sets}',
                          style: TextStyle(
                            color: ModernTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_currentVoiceCoaching != null)
                    VoiceCoachingPlayer(
                      voiceCoaching: _currentVoiceCoaching!,
                      controller: _voiceCoachingController,
                    )
                  else if (_isLoadingVoiceCoaching)
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                  if (currentExercise.notes != null)
                    ModernCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: ModernTheme.accentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentExercise.notes!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (_isCountdownActive)
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '$_countdownSeconds',
                            style: GoogleFonts.outfit(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preparati!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  else if (_setStarted) ...[
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formattedTime,
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: ModernTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tempo Trascorso',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (!_isCountdownActive)
                    if (!_setStarted)
                      ModernButton(
                        text: 'Inizia Serie ${_currentSetNumber + 1}',
                        icon: Icons.play_arrow,
                        onPressed: _startSet,
                      )
                    else
                      ModernButton(
                        text: 'Termina Serie ${_currentSetNumber + 1}',
                        icon: Icons.done,
                        onPressed: () =>
                            _showSetCompletionDialog(currentExercise),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
