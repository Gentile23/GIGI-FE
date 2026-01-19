import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/health_integration_service.dart';
import '../../../data/models/workout_model.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../widgets/workout/session_timer_widget.dart';
import '../../widgets/workout/exercise_focus_card.dart';
import '../../widgets/workout/rest_period_overlay.dart';
import '../../widgets/workout/set_completion_sheet.dart';
import '../../widgets/celebrations/celebration_overlay.dart';
import '../../../core/services/gigi_tts_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/voice_coaching_service.dart';
import 'exercise_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// IMMERSIVE SESSION SCREEN - Sequential workout experience
/// Psychology: Single-task focus + progress visibility = higher completion
/// ═══════════════════════════════════════════════════════════
class ImmersiveSessionScreen extends StatefulWidget {
  final WorkoutDay workoutDay;

  const ImmersiveSessionScreen({super.key, required this.workoutDay});

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen>
    with TickerProviderStateMixin {
  // Session state
  late DateTime _sessionStartTime;
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  bool _isResting = false;
  // ignore: unused_field - will use for future pause functionality
  final bool _isPaused = false;
  bool _showCompletion = false;
  bool _showCelebration = false;

  // Animation controllers
  late AnimationController _slideController;

  // Voice coaching
  late GigiTTSService _gigiTTS;

  // Completed sets tracking
  final Map<String, List<Map<String, dynamic>>> _completedSets = {};

  List<WorkoutExercise> get _mainExercises => widget.workoutDay.mainWorkout;

  WorkoutExercise get _currentExercise => _mainExercises[_currentExerciseIndex];

  WorkoutExercise? get _nextExercise {
    if (_currentSetNumber < _currentExercise.sets) {
      return _currentExercise; // Same exercise, next set
    }
    if (_currentExerciseIndex < _mainExercises.length - 1) {
      return _mainExercises[_currentExerciseIndex + 1];
    }
    return null;
  }

  bool get _isLastSet => _currentSetNumber >= _currentExercise.sets;
  bool get _isLastExercise =>
      _currentExerciseIndex >= _mainExercises.length - 1;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();

    // Slide animation for exercise transitions
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Voice coaching
    final voiceCoachingService = VoiceCoachingService(ApiClient());
    _gigiTTS = GigiTTSService(voiceCoachingService);
    _gigiTTS.initialize();

    // Start workout session in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _gigiTTS.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    await provider.startWorkout(workoutDayId: widget.workoutDay.id);
    HapticService.heavyTap();
  }

  void _onSetComplete(int reps, double? weight) {
    // Record the set
    final exerciseId = _currentExercise.exercise.id;
    if (!_completedSets.containsKey(exerciseId)) {
      _completedSets[exerciseId] = [];
    }
    _completedSets[exerciseId]!.add({
      'setNumber': _currentSetNumber,
      'reps': reps,
      'weight': weight,
    });

    // Log to provider - note: workout logging is done via provider's internal tracking
    // The provider will handle set logging when workout is completed

    // Determine next action
    if (_isLastSet) {
      if (_isLastExercise) {
        // Workout complete!
        _completeWorkout();
      } else {
        // Move to next exercise with rest
        _startRest(isNewExercise: true);
      }
    } else {
      // More sets remaining - start rest
      _startRest(isNewExercise: false);
    }
  }

  void _startRest({required bool isNewExercise}) {
    setState(() {
      _isResting = true;
    });
  }

  void _onRestComplete() {
    setState(() {
      _isResting = false;

      if (_isLastSet) {
        // Move to next exercise
        _currentExerciseIndex++;
        _currentSetNumber = 1;
        HapticService.mediumTap();
      } else {
        // Next set of same exercise
        _currentSetNumber++;
      }
    });
  }

  void _skipRest() {
    HapticService.lightTap();
    _onRestComplete();
  }

  Future<void> _completeWorkout() async {
    HapticService.celebrationPattern();

    // Sync workout to Apple Health / Health Connect
    await _syncWorkoutToHealth();

    if (!mounted) return;

    // Award XP
    final gamificationProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );
    // Refresh gamification stats
    await gamificationProvider.refresh();

    setState(() {
      _showCompletion = true;
      _showCelebration = true;
    });
  }

  /// Sync completed workout to Apple Health / Health Connect
  Future<void> _syncWorkoutToHealth() async {
    try {
      final healthService = HealthIntegrationService();
      await healthService.initialize();

      if (!healthService.isAuthorized) return;

      final duration = DateTime.now().difference(_sessionStartTime);
      final caloriesBurned = duration.inMinutes * 7; // Estimate

      final success = await healthService.writeWorkout(
        startTime: _sessionStartTime,
        endTime: DateTime.now(),
        caloriesBurned: caloriesBurned,
        workoutType: 'strength_training',
      );

      if (success) {
        debugPrint('✅ Workout synced to ${healthService.platformName}');
      }
    } catch (e) {
      debugPrint('Error syncing workout to health: $e');
    }
  }

  void _showSetCompletionSheet() {
    final exerciseId = _currentExercise.exercise.id;
    final previousSets = _completedSets[exerciseId];
    double? previousWeight;
    int? previousReps;

    if (previousSets != null && previousSets.isNotEmpty) {
      final lastSet = previousSets.last;
      previousWeight = lastSet['weight'] as double?;
      previousReps = lastSet['reps'] as int?;
    }

    SetCompletionSheet.show(
      context: context,
      setNumber: _currentSetNumber,
      targetReps: int.tryParse(_currentExercise.reps) ?? 10,
      previousWeight: previousWeight,
      previousReps: previousReps,
      onComplete: _onSetComplete,
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Uscire dalla sessione?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Il progresso di questa sessione verrà perso.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continua',
              style: GoogleFonts.inter(color: CleanTheme.primaryColor),
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

  @override
  Widget build(BuildContext context) {
    if (_mainExercises.isEmpty) {
      return _buildEmptyState();
    }

    if (_showCompletion) {
      return _buildCompletionScreen();
    }

    if (_isResting) {
      return _buildRestScreen();
    }

    return _buildSessionScreen();
  }

  Widget _buildSessionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)],
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Session timer header
              SessionTimerWidget(
                startTime: _sessionStartTime,
                currentExercise: _currentExerciseIndex + 1,
                totalExercises: _mainExercises.length,
                isPaused: _isPaused,
              ),

              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showExitConfirmation,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ESERCIZIO ${_currentExerciseIndex + 1} di ${_mainExercises.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40), // Balance
                  ],
                ),
              ),

              const Spacer(),

              // Exercise focus card
              ExerciseFocusCard(
                exercise: _currentExercise,
                currentSet: _currentSetNumber,
                totalSets: _currentExercise.sets,
                onInfoTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailScreen(
                        workoutExercise: _currentExercise,
                      ),
                    ),
                  );
                },
                // Show skip button for cardio/mobility exercises
                onSkip:
                    (_currentExercise.exerciseType == 'cardio' ||
                        _currentExercise.exerciseType == 'mobility')
                    ? () {
                        HapticService.lightTap();
                        // Skip to next exercise
                        if (_currentExerciseIndex < _mainExercises.length - 1) {
                          setState(() {
                            _currentExerciseIndex++;
                            _currentSetNumber = 1;
                          });
                        } else {
                          _completeWorkout();
                        }
                      }
                    : null,
              ),

              const Spacer(),

              // Complete set button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: GestureDetector(
                  onTap: _showSetCompletionSheet,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.accentGreen,
                          CleanTheme.accentGreen.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SERIE COMPLETATA',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Celebration overlay
          if (_showCelebration)
            CelebrationOverlay(
              style: CelebrationStyle.confetti,
              onComplete: () => setState(() => _showCelebration = false),
            ),
        ],
      ),
    );
  }

  Widget _buildRestScreen() {
    final restSeconds = _currentExercise.restSeconds;
    final isNewExercise = _isLastSet;

    return RestPeriodOverlay(
      totalSeconds: restSeconds,
      nextExercise: _nextExercise,
      isNextExerciseDifferent: isNewExercise,
      onComplete: _onRestComplete,
      onSkip: _skipRest,
    );
  }

  Widget _buildCompletionScreen() {
    final totalSets = _completedSets.values.fold<int>(
      0,
      (sum, sets) => sum + sets.length,
    );
    final duration = DateTime.now().difference(_sessionStartTime);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Trophy icon
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.accentGreen.withValues(alpha: 0.3),
                          CleanTheme.accentGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 80)),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'SESSIONE COMPLETATA!',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.workoutDay.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white60,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCompletionStat(
                        '⏱️',
                        '${duration.inMinutes}',
                        'minuti',
                      ),
                      _buildCompletionStat('💪', '$totalSets', 'serie'),
                      _buildCompletionStat(
                        '🔥',
                        '${duration.inMinutes * 7}',
                        'kcal',
                      ),
                    ],
                  ),

                  const Spacer(),

                  // XP earned banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.accentPurple.withValues(alpha: 0.3),
                          CleanTheme.accentPurple.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: CleanTheme.accentPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text(
                          '+${_mainExercises.length * 10} XP guadagnati',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Finish button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          'TERMINA',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_showCelebration)
            CelebrationOverlay(
              style: CelebrationStyle.confetti,
              onComplete: () => setState(() => _showCelebration = false),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun esercizio',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questo allenamento non ha esercizi.',
              style: GoogleFonts.inter(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
