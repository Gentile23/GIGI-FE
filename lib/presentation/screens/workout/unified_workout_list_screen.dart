import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/workout_provider.dart';
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

/// Screen for executing a custom workout
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

  @override
  void initState() {
    super.initState();
    _initializeVideoIfAvailable();
  }

  void _initializeVideoIfAvailable() {
    if (widget.plan.exercises.isNotEmpty) {
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

  @override
  void dispose() {
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
                  // Sets and reps info
                  CleanCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Serie', '${currentExercise.sets}'),
                        Container(
                          height: 40,
                          width: 1,
                          color: CleanTheme.borderPrimary,
                        ),
                        _buildStatColumn('Rep', currentExercise.reps),
                        Container(
                          height: 40,
                          width: 1,
                          color: CleanTheme.borderPrimary,
                        ),
                        _buildStatColumn(
                          'Riposo',
                          '${currentExercise.restSeconds}s',
                        ),
                      ],
                    ),
                  ),
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
          Container(
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
                      onPressed: () {
                        setState(() {
                          _currentExerciseIndex--;
                          _videoController?.close();
                          _initializeVideoIfAvailable();
                        });
                      },
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Expanded(
                  child: CleanButton(
                    text:
                        _currentExerciseIndex < widget.plan.exercises.length - 1
                        ? 'Prossimo'
                        : 'Completa',
                    icon:
                        _currentExerciseIndex < widget.plan.exercises.length - 1
                        ? Icons.arrow_forward
                        : Icons.check,
                    onPressed: () {
                      if (_currentExerciseIndex <
                          widget.plan.exercises.length - 1) {
                        setState(() {
                          _currentExerciseIndex++;
                          _videoController?.close();
                          _initializeVideoIfAvailable();
                        });
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 ${widget.plan.name} completato!'),
                            backgroundColor: CleanTheme.accentGreen,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CleanTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
