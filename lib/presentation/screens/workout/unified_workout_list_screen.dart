import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_log_provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'workout_screen.dart';
import '../custom_workout/create_custom_workout_screen.dart';

/// Unified screen showing both AI-generated and custom workouts
class UnifiedWorkoutListScreen extends StatefulWidget {
  const UnifiedWorkoutListScreen({super.key});

  @override
  State<UnifiedWorkoutListScreen> createState() =>
      _UnifiedWorkoutListScreenState();
}

class _UnifiedWorkoutListScreenState extends State<UnifiedWorkoutListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CustomWorkoutService _customWorkoutService;
  List<CustomWorkoutPlan> _customPlans = [];
  bool _isLoadingCustom = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _customWorkoutService = CustomWorkoutService(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      _loadCustomWorkouts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomWorkouts() async {
    setState(() => _isLoadingCustom = true);
    final result = await _customWorkoutService.getCustomWorkouts();
    if (mounted) {
      setState(() {
        _isLoadingCustom = false;
        if (result['success'] == true) {
          _customPlans = result['plans'] as List<CustomWorkoutPlan>;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'I Miei Workout',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CleanTheme.primaryColor,
          unselectedLabelColor: CleanTheme.textSecondary,
          indicatorColor: CleanTheme.primaryColor,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Generati'),
            Tab(icon: Icon(Icons.edit_note), text: 'Personalizzati'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAIWorkoutsTab(), _buildCustomWorkoutsTab()],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateCustomWorkoutScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadCustomWorkouts();
                    }
                  },
                  backgroundColor: CleanTheme.primaryColor,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Nuova Scheda',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                )
              : const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAIWorkoutsTab() {
    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, _) {
        if (workoutProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: CleanTheme.primaryColor),
          );
        }

        final currentPlan = workoutProvider.currentPlan;

        if (currentPlan == null || currentPlan.workouts.isEmpty) {
          return _buildEmptyAIState();
        }

        final workouts = currentPlan.workouts;

        return RefreshIndicator(
          onRefresh: () async {
            await workoutProvider.fetchCurrentPlan();
          },
          color: CleanTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return _buildAIWorkoutCard(context, workout, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomWorkoutsTab() {
    if (_isLoadingCustom) {
      return const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      );
    }

    if (_customPlans.isEmpty) {
      return _buildEmptyCustomState();
    }

    return RefreshIndicator(
      onRefresh: _loadCustomWorkouts,
      color: CleanTheme.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: _customPlans.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildCustomWorkoutCard(_customPlans[index]);
        },
      ),
    );
  }

  Widget _buildEmptyAIState() {
    final currentPlan = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentPlan;

    if (currentPlan != null && currentPlan.status == 'processing') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CleanTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              '🤖 AI sta creando il tuo piano',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendere prego...',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: CleanTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Nessun Piano AI Generato',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genera il tuo primo piano dalla Home',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note,
                size: 48,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessuna Scheda Custom',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea la tua scheda personalizzata\nselezionando gli esercizi che preferisci',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIWorkoutCard(
    BuildContext context,
    WorkoutDay workout,
    int index,
  ) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseExecutionScreen(workout: workout),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.focus,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Inizia',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.timer_outlined,
                '${workout.estimatedDuration} min',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.fitness_center_outlined,
                '${workout.exercises.length} esercizi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomWorkoutCard(CustomWorkoutPlan plan) {
    return CleanCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomWorkoutExecutionScreen(plan: plan),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: CleanTheme.accentPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Text(
                        plan.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: CleanTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateCustomWorkoutScreen(existingPlan: plan),
                        ),
                      );
                      if (result == true) {
                        _loadCustomWorkouts();
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Inizia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.format_list_numbered,
                '${plan.exerciseCount} esercizi',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.timer_outlined,
                '~${plan.estimatedDuration} min',
              ),
            ],
          ),
          if (plan.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plan.exercises.take(3).map((we) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    we.exercise.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CleanTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen for executing a custom workout with full logging capabilities
class CustomWorkoutExecutionScreen extends StatefulWidget {
  final CustomWorkoutPlan plan;

  const CustomWorkoutExecutionScreen({super.key, required this.plan});

  @override
  State<CustomWorkoutExecutionScreen> createState() =>
      _CustomWorkoutExecutionScreenState();
}

class _CustomWorkoutExecutionScreenState
    extends State<CustomWorkoutExecutionScreen> {
  int _currentExerciseIndex = 0;
  YoutubePlayerController? _videoController;

  // Set logging data: Map<exerciseIndex, Map<setNumber, SetLogData>>
  final Map<int, Map<int, _SetLogData>> _setData = {};

  // Previous workout data per exercise
  final Map<int, Map<int, Map<String, dynamic>>> _previousData = {};
  bool _loadingPrevious = true;

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isRestTimerActive = false;

  @override
  void initState() {
    super.initState();
    _initializeSetData();
    _initializeVideoIfAvailable();
    _loadPreviousData();
  }

  void _initializeSetData() {
    for (int i = 0; i < widget.plan.exercises.length; i++) {
      final exercise = widget.plan.exercises[i];
      _setData[i] = {};
      for (int s = 1; s <= exercise.sets; s++) {
        _setData[i]![s] = _SetLogData(reps: int.tryParse(exercise.reps) ?? 10);
      }
    }
  }

  Future<void> _loadPreviousData() async {
    setState(() => _loadingPrevious = true);

    try {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

      for (int i = 0; i < widget.plan.exercises.length; i++) {
        final exercise = widget.plan.exercises[i].exercise;
        final data = await provider.getExerciseLastPerformance(exercise.id);

        if (data != null && data['sets'] != null) {
          _previousData[i] = {};
          for (var setData in data['sets'] as List) {
            final setNumber = setData['set_number'] as int;
            _previousData[i]![setNumber] = {
              'weight': (setData['weight_kg'] as num?)?.toDouble() ?? 0,
              'reps': setData['reps'] as int? ?? 0,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading previous data: $e');
    }

    if (mounted) {
      setState(() => _loadingPrevious = false);
    }
  }

  void _initializeVideoIfAvailable() {
    _videoController?.close();
    _videoController = null;

    if (widget.plan.exercises.isNotEmpty &&
        _currentExerciseIndex < widget.plan.exercises.length) {
      final exercise = widget.plan.exercises[_currentExerciseIndex].exercise;
      if (exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty) {
        String? videoId = _extractYoutubeId(exercise.videoUrl!);
        if (videoId != null) {
          _videoController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            params: const YoutubePlayerParams(
              mute: false,
              showControls: true,
              showFullscreenButton: true,
            ),
          );
        }
      }
    }
  }

  String? _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = seconds;
      _isRestTimerActive = true;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining <= 0) {
        timer.cancel();
        setState(() => _isRestTimerActive = false);
        // Vibrate or play sound when timer ends
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _restSecondsRemaining--);
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

  @override
  void dispose() {
    _restTimer?.cancel();
    _videoController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.plan.name)),
        body: Center(
          child: Text(
            'Aggiungi esercizi per iniziare',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
        ),
      );
    }

    final currentExercise = widget.plan.exercises[_currentExerciseIndex];
    final restSeconds = currentExercise.restSeconds > 0
        ? currentExercise.restSeconds
        : 60;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.plan.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentExerciseIndex + 1) / widget.plan.exercises.length,
            backgroundColor: CleanTheme.borderSecondary,
            valueColor: const AlwaysStoppedAnimation<Color>(
              CleanTheme.primaryColor,
            ),
          ),

          // Rest Timer Banner
          if (_isRestTimerActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: CleanTheme.primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Riposo: ${_restSecondsRemaining}s',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            _startRestTimer(_restSecondsRemaining + 30),
                        child: const Text(
                          '+30s',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        onPressed: _stopRestTimer,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise counter
                  Text(
                    'Esercizio ${_currentExerciseIndex + 1} di ${widget.plan.exercises.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Exercise name
                  Text(
                    currentExercise.exercise.name,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Video player
                  if (_videoController != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayer(controller: _videoController!),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Set Logging Table Header
                  _buildSetTableHeader(),
                  const SizedBox(height: 8),

                  // Set Rows
                  ...List.generate(currentExercise.sets, (index) {
                    final setNumber = index + 1;
                    return _buildSetRow(
                      setNumber,
                      currentExercise,
                      restSeconds,
                    );
                  }),

                  // Notes
                  if (currentExercise.notes != null &&
                      currentExercise.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    CleanCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.notes,
                            color: CleanTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentExercise.notes!,
                              style: GoogleFonts.inter(
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildSetTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Checkbox space
          Expanded(flex: 1, child: Text('SET', style: _headerStyle())),
          Expanded(
            flex: 2,
            child: Text(
              'PREC',
              style: _headerStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'KG',
              style: _headerStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'REP',
              style: _headerStyle(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'RPE',
              style: _headerStyle(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: CleanTheme.textSecondary,
  );

  Widget _buildSetRow(
    int setNumber,
    CustomWorkoutExercise exercise,
    int restSeconds,
  ) {
    final setLog = _setData[_currentExerciseIndex]?[setNumber];
    final prevData = _previousData[_currentExerciseIndex]?[setNumber];
    final isCompleted = setLog?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
            : CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? CleanTheme.accentGreen
              : CleanTheme.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 40,
            child: Checkbox(
              value: isCompleted,
              onChanged: (value) => _toggleSet(setNumber, value, restSeconds),
              activeColor: CleanTheme.accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Set number
          Expanded(
            flex: 1,
            child: Text(
              '$setNumber',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),

          // Previous data
          Expanded(
            flex: 2,
            child: _loadingPrevious
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    prevData != null
                        ? '${prevData['weight']}×${prevData['reps']}'
                        : '-',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          // Weight input
          Expanded(
            flex: 2,
            child: _buildNumberInput(
              value: setLog?.weight ?? 0,
              onChanged: (v) => setState(() => setLog?.weight = v),
              suffix: '',
            ),
          ),

          // Reps input
          Expanded(
            flex: 2,
            child: _buildNumberInput(
              value: (setLog?.reps ?? 0).toDouble(),
              onChanged: (v) => setState(() => setLog?.reps = v.toInt()),
              suffix: '',
              isInt: true,
            ),
          ),

          // RPE
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showRPEPicker(setNumber),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRPEColor(setLog?.rpe ?? 7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${setLog?.rpe ?? 7}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getRPEColor(setLog?.rpe ?? 7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required double value,
    required ValueChanged<double> onChanged,
    required String suffix,
    bool isInt = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onChanged(value > 0 ? value - (isInt ? 1 : 2.5) : 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.remove,
                size: 16,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isInt ? value.toInt().toString() : value.toStringAsFixed(1),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value + (isInt ? 1 : 2.5)),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.add,
                size: 16,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 5) return Colors.green;
    if (rpe <= 7) return Colors.orange;
    if (rpe <= 8) return Colors.deepOrange;
    return Colors.red;
  }

  void _toggleSet(int setNumber, bool? value, int restSeconds) {
    setState(() {
      _setData[_currentExerciseIndex]?[setNumber]?.isCompleted = value ?? false;
    });

    // Auto-start rest timer when completing a set
    if (value == true) {
      _startRestTimer(restSeconds);
      HapticFeedback.mediumImpact();
    }
  }

  void _showRPEPicker(int setNumber) {
    final setLog = _setData[_currentExerciseIndex]?[setNumber];

    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.cardColor,
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
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quanto è stato difficile questo set?',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (index) {
                final rpe = index + 1;
                final isSelected = setLog?.rpe == rpe;
                return GestureDetector(
                  onTap: () {
                    setState(() => setLog?.rpe = rpe);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getRPEColor(rpe)
                          : _getRPEColor(rpe).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$rpe',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : _getRPEColor(rpe),
                          ),
                        ),
                        if (rpe == 10)
                          Text(
                            'MAX',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? Colors.white
                                  : _getRPEColor(rpe),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final allSetsCompleted =
        _setData[_currentExerciseIndex]?.values.every((s) => s.isCompleted) ??
        false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CleanTheme.surfaceColor,
        border: Border(top: BorderSide(color: CleanTheme.borderPrimary)),
      ),
      child: Row(
        children: [
          if (_currentExerciseIndex > 0)
            Expanded(
              child: CleanButton(
                text: 'Precedente',
                icon: Icons.arrow_back,
                backgroundColor: CleanTheme.borderSecondary,
                textColor: CleanTheme.textPrimary,
                onPressed: _goToPreviousExercise,
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 12),
          Expanded(
            child: CleanButton(
              text: _currentExerciseIndex < widget.plan.exercises.length - 1
                  ? (allSetsCompleted ? 'Prossimo ✓' : 'Prossimo')
                  : (allSetsCompleted ? 'Completa 🎉' : 'Completa'),
              icon: _currentExerciseIndex < widget.plan.exercises.length - 1
                  ? Icons.arrow_forward
                  : Icons.check,
              backgroundColor: allSetsCompleted
                  ? CleanTheme.accentGreen
                  : CleanTheme.primaryColor,
              onPressed: _goToNextOrComplete,
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousExercise() {
    _stopRestTimer();
    setState(() {
      _currentExerciseIndex--;
      _videoController?.close();
      _initializeVideoIfAvailable();
    });
  }

  void _goToNextOrComplete() {
    _stopRestTimer();
    if (_currentExerciseIndex < widget.plan.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _videoController?.close();
        _initializeVideoIfAvailable();
      });
    } else {
      // Save workout log to backend
      _saveWorkoutLog();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${widget.plan.name} completato!'),
          backgroundColor: CleanTheme.accentGreen,
        ),
      );
    }
  }

  Future<void> _saveWorkoutLog() async {
    try {
      final apiClient = ApiClient();

      // Collect exercise data from the workout
      final exerciseLogs = widget.plan.exercises.asMap().entries.map((entry) {
        final exercise = entry.value;
        return {
          'exercise_id': exercise.exercise.id,
          'exercise_name': exercise.exercise.name,
          'sets_completed': exercise.sets,
          'reps_target': exercise.reps,
          'rest_seconds': exercise.restSeconds,
        };
      }).toList();

      await apiClient.post(
        '/workout-logs',
        body: {
          'workout_plan_id': widget.plan.id,
          'workout_name': widget.plan.name,
          'exercises': exerciseLogs,
          'duration_minutes': 30, // Approximate
          'completed_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error saving workout log: $e');
    }
  }
}

/// Data class for tracking set logging
class _SetLogData {
  double weight;
  int reps;
  int rpe;
  bool isCompleted;

  _SetLogData({
    this.weight = 0,
    this.reps = 10,
    this.rpe = 7,
    this.isCompleted = false,
  });
}
