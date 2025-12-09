import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/trial_workout_model.dart';
import '../../../data/models/voice_coaching_model.dart';
import '../../../data/services/trial_workout_service.dart';
import '../../../data/services/voice_coaching_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
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
  final int _totalRestTime = 0;
  int _overallFatigue = 3;
  bool _isSubmitting = false;

  bool _setStarted = false;
  int _currentSetNumber = 0;
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

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _formattedTime = '00:00';

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
              duration: 10,
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
        debugPrint('Error loading voice coaching: $e');
        if (mounted) {
          setState(() {
            _isLoadingVoiceCoaching = false;
          });
        }
      }
    }
  }

  Future<void> _startSet() async {
    if (_currentSetNumber == 0 && _currentVoiceCoaching == null) {
      await _loadVoiceCoaching();
    }

    _voiceCoachingController.playPre();

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
          backgroundColor: CleanTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Serie ${_currentSetNumber + 1}/${exercise.sets} completata!',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formattedTime,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Quante ripetizioni hai fatto?',
                    labelStyle: GoogleFonts.inter(
                      color: CleanTheme.textSecondary,
                    ),
                    hintText: 'Es: 10',
                    filled: true,
                    fillColor: CleanTheme.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: CleanTheme.borderPrimary,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: CleanTheme.borderPrimary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: CleanTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    'Esercizio a corpo libero',
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                  ),
                  value: isBodyweight,
                  onChanged: (value) => setState(() => isBodyweight = value),
                  activeThumbColor: CleanTheme.primaryColor,
                ),
                if (!isBodyweight) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Peso utilizzato (kg)',
                      labelStyle: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                      ),
                      hintText: 'Es: 20.5',
                      filled: true,
                      fillColor: CleanTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CleanTheme.borderPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            CleanButton(
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

    if (_currentSetNumber >= exercise.sets) {
      _showDifficultyDialog();
    }
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Quanto è stato difficile?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final difficulty = index + 1;
            return ListTile(
              title: Text(
                _getDifficultyLabel(difficulty),
                style: GoogleFonts.inter(color: CleanTheme.textPrimary),
              ),
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
      _currentSetNumber = 0;
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
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Livello di Fatica',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Come ti senti dopo questo allenamento?',
                  style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ...List.generate(5, (index) {
                  final level = index + 1;
                  final isSelected = _overallFatigue == level;
                  return ListTile(
                    title: Text(
                      _getFatigueLabel(level),
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.borderPrimary,
                          width: 2,
                        ),
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    onTap: () {
                      setState(() => _overallFatigue = level);
                      setDialogState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            );
          },
        ),
        actions: [CleanButton(text: 'Completa Trial', onPressed: _submitTrial)],
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
    Navigator.pop(context);

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
              backgroundColor: CleanTheme.accentRed,
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
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );
    }

    final currentExercise =
        widget.trialWorkout.exercises[_currentExerciseIndex];
    final progress =
        (_currentExerciseIndex + 1) / widget.trialWorkout.exercises.length;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Trial Workout',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
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
                  color: CleanTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentExerciseIndex + 1}/${widget.trialWorkout.exercises.length}',
                  style: GoogleFonts.inter(
                    color: CleanTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CleanTheme.primaryColor,
              ),
              minHeight: 4,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentExerciseIndex == 0 && _currentSetNumber == 0)
                    CleanCard(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CleanTheme.accentPurple.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_outlined,
                              color: CleanTheme.accentPurple,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎤 Voice Coaching GRATIS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: CleanTheme.accentPurple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prova il coach vocale durante questo trial!',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: CleanTheme.textSecondary,
                                  ),
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
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Serie ${_currentSetNumber + 1}/${currentExercise.sets}',
                          style: GoogleFonts.inter(
                            color: CleanTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
                    const Center(
                      child: CircularProgressIndicator(
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (currentExercise.notes != null)
                    CleanCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CleanTheme.accentBlue.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: CleanTheme.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentExercise.notes!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CleanTheme.textSecondary,
                              ),
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
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preparati!',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
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
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tempo Trascorso',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (!_isCountdownActive)
                    if (!_setStarted)
                      CleanButton(
                        text: 'Inizia Serie ${_currentSetNumber + 1}',
                        icon: Icons.play_arrow,
                        width: double.infinity,
                        onPressed: _startSet,
                      )
                    else
                      CleanButton(
                        text: 'Termina Serie ${_currentSetNumber + 1}',
                        icon: Icons.check,
                        width: double.infinity,
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
