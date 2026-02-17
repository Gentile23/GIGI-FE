import 'package:flutter/material.dart';
import '../../../core/services/workout_audio_orchestrator.dart';
import '../../../core/services/music_integration_service.dart';
import '../../../data/models/exercise_intro_model.dart';
import '../../../data/services/voice_coaching_service.dart';
import '../../widgets/voice_coaching/mode_selection_sheet.dart';
import '../../widgets/voice_coaching/immersive_coaching_overlay.dart';
import '../../screens/paywall/paywall_screen.dart'; // Import PaywallScreen
import '../../../data/services/quota_service.dart'; // Import QuotaService

/// Mixin that provides voice coaching integration for workout screens
///
/// Usage:
/// ```dart
/// class _MyWorkoutScreenState extends State<MyWorkoutScreen>
///     with VoiceCoachingIntegrationMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Stack(
///       children: [
///         // Your workout content
///         buildCoachingOverlay(),
///       ],
///     );
///   }
/// }
/// ```
mixin VoiceCoachingIntegrationMixin<T extends StatefulWidget> on State<T> {
  late WorkoutAudioOrchestrator _audioOrchestrator;
  late MusicIntegrationService _musicService;
  VoiceCoachingService? _voiceCoachingService;

  ExerciseIntroScript? _currentIntro;
  String? _currentText;
  bool _showOverlay = false;
  CoachingMode _selectedMode = CoachingMode.voice;
  bool _rememberChoice = false;

  // Getters
  WorkoutAudioOrchestrator get audioOrchestrator => _audioOrchestrator;
  MusicIntegrationService get musicService => _musicService;
  ExerciseIntroScript? get currentIntro => _currentIntro;
  String? get currentText => _currentText;
  bool get showOverlay => _showOverlay;
  CoachingMode get selectedMode => _selectedMode;

  /// Initialize voice coaching - call in initState
  void initVoiceCoaching(VoiceCoachingService voiceCoachingService) {
    _voiceCoachingService = voiceCoachingService;
    _audioOrchestrator = WorkoutAudioOrchestrator(voiceCoachingService);
    _musicService = MusicIntegrationService();

    // Listen to orchestrator changes
    _audioOrchestrator.addListener(_onOrchestratorUpdate);

    // Initialize music service
    _musicService.initialize();
  }

  /// Dispose voice coaching - call in dispose
  void disposeVoiceCoaching() {
    _audioOrchestrator.removeListener(_onOrchestratorUpdate);
    _audioOrchestrator.dispose();
    _musicService.dispose();
  }

  void _onOrchestratorUpdate() {
    if (mounted) {
      setState(() {
        // Update overlay visibility based on phase
        _showOverlay = _audioOrchestrator.currentPhase != CoachingPhase.idle;
      });
    }
  }

  /// Show mode selection before starting exercise
  Future<void> showModeSelection({
    required BuildContext context,
    required String exerciseName,
    required String exerciseId,
    required VoidCallback onStart,
  }) async {
    // Check quota for Execute with GiGi
    final quotaService = QuotaService();
    final checkResult = await quotaService.checkAndRecord(
      QuotaAction.executeWithGigi,
    );

    if (!checkResult.canPerform) {
      if (context.mounted) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const PaywallScreen()));
      }
      return;
    }

    // Fetch personalized intro first
    await _fetchIntro(exerciseId);

    if (!context.mounted) return;

    await ModeSelectionSheet.show(
      context,
      exerciseName: exerciseName,
      intro: _currentIntro,
      currentMode: _selectedMode,
      rememberChoice: _rememberChoice,
      onModeSelected: (mode, remember) {
        setState(() {
          _selectedMode = mode;
          _rememberChoice = remember;
          _showOverlay = true;
        });
        _audioOrchestrator.setCoachingMode(mode);
        onStart();
      },
      onSkipIntro: () {
        setState(() {
          _showOverlay = false;
        });
        onStart();
      },
    );
  }

  /// Fetch personalized intro for exercise
  Future<void> _fetchIntro(String exerciseId) async {
    if (_voiceCoachingService == null) return;

    try {
      _currentIntro = await _voiceCoachingService!.getPersonalizedIntro(
        exerciseId,
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching intro: $e');
    }
  }

  /// Trigger workout events
  void onExerciseSelected(String exerciseId) {
    _audioOrchestrator.onWorkoutEvent(
      WorkoutEvent.exerciseSelected,
      data: {'exerciseId': exerciseId},
    );
  }

  void onSetStarted({
    required int setNumber,
    required int totalSets,
    required int totalReps,
  }) {
    _audioOrchestrator.onWorkoutEvent(
      WorkoutEvent.setStarted,
      data: {
        'setNumber': setNumber,
        'totalSets': totalSets,
        'totalReps': totalReps,
      },
    );
  }

  void onRepCompleted(int repNumber) {
    _audioOrchestrator.onWorkoutEvent(
      WorkoutEvent.repCompleted,
      data: {'repNumber': repNumber},
    );
  }

  void onSetCompleted() {
    _audioOrchestrator.onWorkoutEvent(WorkoutEvent.setCompleted);
  }

  void onRestStarted(int restSeconds) {
    _audioOrchestrator.onWorkoutEvent(
      WorkoutEvent.restStarted,
      data: {'restSeconds': restSeconds},
    );
  }

  void onWorkoutCompleted() {
    _audioOrchestrator.onWorkoutEvent(WorkoutEvent.workoutCompleted);
  }

  void onPauseWorkout() {
    _audioOrchestrator.onWorkoutEvent(WorkoutEvent.pause);
  }

  void onResumeWorkout() {
    _audioOrchestrator.onWorkoutEvent(WorkoutEvent.resume);
  }

  /// Build the coaching overlay widget - add to your Stack
  Widget buildCoachingOverlay() {
    return ImmersiveCoachingOverlay(
      orchestrator: _audioOrchestrator,
      currentText: _currentText,
      isVisible: _showOverlay,
      onMuteToggle: () {
        _audioOrchestrator.toggleMute();
      },
    );
  }

  /// Build a "Start with Gigi" button
  Widget buildStartWithGigiButton({
    required BuildContext context,
    required String exerciseName,
    required String exerciseId,
    required VoidCallback onStart,
  }) {
    return ElevatedButton.icon(
      onPressed: () => showModeSelection(
        context: context,
        exerciseName: exerciseName,
        exerciseId: exerciseId,
        onStart: onStart,
      ),
      icon: const Text('🎤', style: TextStyle(fontSize: 20)),
      label: const Text('Inizia con Gigi'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
