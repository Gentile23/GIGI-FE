import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/services/api_client.dart';
import '../../screens/paywall/paywall_screen.dart';
import 'exercise_search_screen.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// Screen for creating or editing a custom workout plan
class CreateCustomWorkoutScreen extends StatefulWidget {
  final CustomWorkoutPlan? existingPlan;

  const CreateCustomWorkoutScreen({super.key, this.existingPlan});

  @override
  State<CreateCustomWorkoutScreen> createState() =>
      _CreateCustomWorkoutScreenState();
}

class _CreateCustomWorkoutScreenState extends State<CreateCustomWorkoutScreen> {
  late CustomWorkoutService _customWorkoutService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Local list of exercises to add
  List<_LocalExercise> _exercises = [];
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _allowPop = false;
  late String _initialSnapshot;
  bool get isEditing => widget.existingPlan != null;
  late QuotaService _quotaService;
  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    _customWorkoutService = CustomWorkoutService(ApiClient());
    _quotaService = QuotaService();

    if (isEditing) {
      _nameController.text = widget.existingPlan!.name;
      _descriptionController.text = widget.existingPlan!.description ?? '';
      _exercises = widget.existingPlan!.exercises
          .map(
            (e) => _LocalExercise(
              id: UniqueKey().toString(),
              exercise: e.exercise,
              sets: e.sets,
              reps: e.reps,
              restSeconds: e.restSeconds,
              restSecondsPerSet: e.restSecondsPerSet,
              exerciseType: e.exerciseType ?? 'strength',
              position: e.position ?? 'main',
              notes: e.notes,
            ),
          )
          .toList();
    }

    _initialSnapshot = _buildSnapshot();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addAtLeastOneExercise),
          backgroundColor: CleanTheme.accentOrange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Check quota for new workouts only
    if (!isEditing) {
      final quotaCheck = await _quotaService.canPerformAction(
        QuotaAction.customWorkout,
      );
      if (!quotaCheck.canPerform) {
        setState(() => _isSaving = false);
        if (mounted) {
          _showQuotaExceededDialog(quotaCheck.reason);
        }
        return;
      }
    }

    final request = CustomWorkoutRequest(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      exercises: _exercises
          .map(
            (e) => CustomWorkoutExerciseRequest(
              exerciseId: e.exercise.id,
              sets: e.sets,
              reps: e.reps,
              restSeconds: e.restSeconds,
              restSecondsPerSet: e.restSecondsPerSet,
              exerciseType: e.exerciseType,
              position: e.position,
              notes: e.notes,
            ),
          )
          .toList(),
    );

    final result = isEditing
        ? await _customWorkoutService.updateCustomWorkout(
            widget.existingPlan!.id,
            request,
          )
        : await _customWorkoutService.createCustomWorkout(request);

    setState(() => _isSaving = false);

    if (result['success'] == true) {
      // Record quota usage for new workouts
      if (!isEditing) {
        await _quotaService.recordUsage(QuotaAction.customWorkout);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? AppLocalizations.of(context)!.workoutUpdated
                  : AppLocalizations.of(context)!.workoutCreated,
            ),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
        setState(() => _allowPop = true);
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Errore nel salvataggio'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  String _buildSnapshot() {
    final exerciseSnapshot = _exercises
        .map(
          (exercise) => [
            exercise.exercise.id,
            exercise.sets,
            exercise.reps.trim(),
            exercise.restSeconds,
            (exercise.restSecondsPerSet ?? []).join(','),
            exercise.exerciseType,
            exercise.position,
            exercise.notes?.trim() ?? '',
          ].join('|'),
        )
        .join(';;');

    return [
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      exerciseSnapshot,
    ].join('::');
  }

  bool get _hasUnsavedChanges => _buildSnapshot() != _initialSnapshot;
  bool get _shouldConfirmExit => _hasUnsavedChanges;

  Future<void> _handleBackPressed() async {
    if (_isBusy) return;

    if (!_shouldConfirmExit) {
      setState(() => _allowPop = true);
      if (mounted) Navigator.pop(context);
      return;
    }

    final action = await _showDiscardChangesDialog();
    if (!mounted) return;

    if (action == 'discard') {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    } else if (action == 'save') {
      await _saveWorkout();
    }
  }

  Future<String?> _showDiscardChangesDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sei sicuro di tornare indietro?',
          style: GoogleFonts.outfit(
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Perderai tutto quello che non hai salvato.',
          style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(
              'Esci senza salvare',
              style: GoogleFonts.outfit(color: CleanTheme.accentRed),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Salva',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkout() async {
    if (!isEditing || _isBusy) return;

    final plan = widget.existingPlan!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.cardColor,
        title: Text(
          AppLocalizations.of(context)!.deleteWorkoutTitle,
          style: GoogleFonts.outfit(
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare "${plan.name}"?',
          style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.accentRed,
            ),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: GoogleFonts.outfit(color: CleanTheme.textOnDark),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result = await _customWorkoutService.deleteCustomWorkout(plan.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (result['success'] == true) {
      setState(() => _allowPop = true);
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Errore nell\'eliminazione'),
        backgroundColor: CleanTheme.accentRed,
      ),
    );
  }

  void _showQuotaExceededDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: CleanTheme.accentOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.limitReached,
                style: GoogleFonts.outfit(
                  color: CleanTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reason,
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.quotaCustomWorkoutDesc,
              style: GoogleFonts.inter(
                color: CleanTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.upgradePro,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercises() async {
    final result = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSearchScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        for (var ex in result) {
          String pos = 'main';
          if (ex.exerciseType == 'warmup') pos = 'warmup';
          if (ex.exerciseType == 'cardio') pos = 'cardio';

          int defaultSets = (pos == 'warmup' || pos == 'cardio') ? 1 : 3;
          String defaultReps = (pos == 'warmup' || pos == 'cardio')
              ? '10 min'
              : '10';

          _exercises.add(
            _LocalExercise(
              id: UniqueKey().toString(),
              exercise: ex,
              sets: defaultSets,
              reps: defaultReps,
              restSeconds: 90,
              restSecondsPerSet: List<int>.filled(defaultSets, 90),
              exerciseType: ex.exerciseType,
              position: pos,
            ),
          );
        }
      });
    }
  }

  void _editExercise(int index) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditExerciseSheet(
        exercise: _exercises[index],
        onSave: (updated) {
          setState(() => _exercises[index] = updated);
        },
        onRemove: () {
          setState(() => _exercises.removeAt(index));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _handleBackPressed,
          ),
          title: Text(
            isEditing
                ? AppLocalizations.of(context)!.editWorkout
                : AppLocalizations.of(context)!.newWorkout,
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
            if (isEditing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: _isBusy ? null : _deleteWorkout,
                  style: IconButton.styleFrom(
                    backgroundColor: CleanTheme.accentRed.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: CleanTheme.accentRed,
                    side: BorderSide(
                      color: CleanTheme.accentRed.withValues(alpha: 0.35),
                    ),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _isBusy ? null : _saveWorkout,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CleanTheme.textOnDark,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.save,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                  foregroundColor: CleanTheme.textOnDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 1. Interactive Header (Brain-Friendly)
                    _buildModernHeader(),

                    // 2. Vertical Reorderable Phases
                    Expanded(child: _buildReorderablePhases()),
                  ],
                ),
                // 3. Floating Action Bottom (optional, but keep it clean)
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: CleanTheme.surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Identity Card
          Container(
            decoration: BoxDecoration(
              color: CleanTheme.steelDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CleanTheme.steelMid.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: CleanTheme.textOnDark,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.workoutNameLabel,
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(
                          context,
                        )!.workoutNameRequired;
                      }
                      return null;
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.descriptionOptional,
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Power Profile / Intensity Visualization
          _buildPowerProfile(),
        ],
      ),
    );
  }

  Widget _buildPowerProfile() {
    // Brain-friendly intensity visualization
    final warmupCount = _exercises.where((e) => e.position == 'warmup').length;
    final mainCount = _exercises.where((e) => e.position == 'main').length;
    final cooldownCount = _exercises
        .where((e) => e.position == 'post_workout')
        .length;
    final total = _exercises.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PROFILO ENERGETICO",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: CleanTheme.textSecondary,
              ),
            ),
            Text(
              "$total esercizi",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CleanTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (warmupCount > 0)
                  Expanded(
                    flex: warmupCount,
                    child: Container(color: CleanTheme.accentOrange),
                  ),
                if (mainCount > 0)
                  Expanded(
                    flex: mainCount,
                    child: Container(color: CleanTheme.primaryColor),
                  ),
                if (cooldownCount > 0)
                  Expanded(
                    flex: cooldownCount,
                    child: Container(color: CleanTheme.accentGreen),
                  ),
                if (total == 0)
                  Expanded(child: Container(color: CleanTheme.borderSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderablePhases() {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 48,
              color: CleanTheme.textTertiary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Nessun esercizio aggiunto",
              style: GoogleFonts.outfit(
                color: CleanTheme.textTertiary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: _exercises.length + 1, // +1 for final spacer
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      proxyDecorator: (child, index, animation) {
        return Material(color: Colors.transparent, elevation: 0, child: child);
      },
      itemBuilder: (context, index) {
        if (index == _exercises.length) {
          return const SizedBox(height: 100, key: ValueKey('final_spacer'));
        }

        return _buildExerciseItem(
          index,
          key: ValueKey('ex_${_exercises[index].id}'),
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex >= _exercises.length) return; // Prevent moving the spacer
    if (newIndex > _exercises.length) newIndex = _exercises.length;

    if (newIndex > oldIndex) newIndex -= 1;

    setState(() {
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });

    HapticService.selectionClick();
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CleanTheme.backgroundColor.withValues(alpha: 0.0),
              CleanTheme.backgroundColor,
            ],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _addExercises,
            icon: const Icon(Icons.add_rounded, size: 24),
            label: Text(
              "AGGIUNGI ESERCIZIO",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.primaryColor,
              foregroundColor: CleanTheme.textOnDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: CleanTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(int index, {Key? key}) {
    final exercise = _exercises[index];

    // Contextual Color Coding
    final Color phaseColor = exercise.position == 'warmup'
        ? CleanTheme
              .accentOrange // 🔥 Warmup (Arancione)
        : exercise.position == 'cardio'
        ? CleanTheme
              .accentRed // ⚡ Cardio (Rosso)
        : CleanTheme.accentBlue; // 💪 Workout (Acciaio / Blu)

    final IconData phaseIcon = exercise.position == 'warmup'
        ? Icons.local_fire_department_rounded
        : exercise.position == 'cardio'
        ? Icons.bolt_rounded
        : Icons.fitness_center_rounded;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.borderSecondary.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Color Indicator (Side Bar)
              Container(width: 6, color: phaseColor),
              // 2. Main Content
              Expanded(
                child: InkWell(
                  onTap: () => _editExercise(index),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Phase-Specific Icon Badge
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(phaseIcon, color: phaseColor, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                exercise.exercise.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: CleanTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    exercise.position == 'warmup'
                                        ? "MOBILITÀ"
                                        : exercise.position == 'cardio'
                                        ? "CARDIO"
                                        : "WORKOUT",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: phaseColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: CleanTheme.textTertiary.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    "${exercise.sets} SERIE",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: CleanTheme.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: CleanTheme.textTertiary.withValues(
                                        alpha: 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    "${exercise.reps} RIP.",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: CleanTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Drag Handle
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8, right: 8),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: CleanTheme.textTertiary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local class to track exercise with its parameters
class _LocalExercise {
  final String id;
  final Exercise exercise;
  int sets;
  String reps;
  int restSeconds;
  List<int>? restSecondsPerSet;
  String exerciseType;
  String position;
  String? notes;

  _LocalExercise({
    required this.id,
    required this.exercise,
    this.sets = 3,
    this.reps = '10',
    this.restSeconds = 60,
    this.restSecondsPerSet,
    this.exerciseType = 'strength',
    this.position = 'main',
    this.notes,
  });
}

/// Bottom sheet for editing exercise parameters
class _EditExerciseSheet extends StatefulWidget {
  final _LocalExercise exercise;
  final Function(_LocalExercise) onSave;
  final VoidCallback onRemove;

  const _EditExerciseSheet({
    required this.exercise,
    required this.onSave,
    required this.onRemove,
  });

  @override
  State<_EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<_EditExerciseSheet> {
  late List<TextEditingController> _repsControllers;
  late List<TextEditingController> _restControllers;
  late TextEditingController _notesController;
  late TextEditingController _customSetsController;
  late TextEditingController _customTargetController;
  late TextEditingController _customRestController;
  late String _exerciseType;
  late String _position;
  late int _sets;
  late int _restSeconds;
  bool _isUniformReps = true;
  bool _isUniformRest = true;
  late String _globalReps;
  late int _globalRestSeconds;

  @override
  void initState() {
    super.initState();
    _sets = widget.exercise.sets;
    _restSeconds = widget.exercise.restSeconds;
    _notesController = TextEditingController(text: widget.exercise.notes ?? '');
    _exerciseType = widget.exercise.exerciseType;
    _position = widget.exercise.position;

    final repsList = widget.exercise.reps
        .split(',')
        .map((s) => s.trim())
        .toList();
    _isUniformReps =
        repsList.length <= 1 || repsList.every((r) => r == repsList[0]);
    _globalReps = repsList.isNotEmpty ? repsList[0] : '10';

    final initialRestPerSet =
        widget.exercise.restSecondsPerSet ??
        List<int>.filled(_sets, widget.exercise.restSeconds);
    final normalizedInitialRestPerSet = _normalizeRestPerSetValues(
      initialRestPerSet,
    );
    _isUniformRest =
        normalizedInitialRestPerSet.length <= 1 ||
        normalizedInitialRestPerSet.every(
          (v) => v == normalizedInitialRestPerSet.first,
        );
    _globalRestSeconds = normalizedInitialRestPerSet.isNotEmpty
        ? normalizedInitialRestPerSet.first
        : _restSeconds;

    _customSetsController = TextEditingController(text: _sets.toString());
    _customTargetController = TextEditingController(
      text: _isUniformReps && _globalReps != 'A cedimento' ? _globalReps : '',
    );
    _customRestController = TextEditingController(
      text: _globalRestSeconds.toString(),
    );

    _initializeRepsControllers();
    _initializeRestControllers(normalizedInitialRestPerSet);
  }

  void _initializeRepsControllers() {
    final repsList = widget.exercise.reps
        .split(',')
        .map((s) => s.trim())
        .toList();
    _repsControllers = List.generate(
      _sets,
      (index) => TextEditingController(
        text: index < repsList.length
            ? repsList[index]
            : (repsList.isNotEmpty ? repsList.last : '10'),
      ),
    );
  }

  void _updateRepsControllers() {
    if (_sets <= 0 || _sets > 20) return;

    if (_sets != _repsControllers.length) {
      if (_sets > _repsControllers.length) {
        final lastValue = _repsControllers.isNotEmpty
            ? _repsControllers.last.text
            : '10';
        for (int i = _repsControllers.length; i < _sets; i++) {
          _repsControllers.add(TextEditingController(text: lastValue));
        }
      } else {
        for (int i = _repsControllers.length - 1; i >= _sets; i--) {
          _repsControllers[i].dispose();
          _repsControllers.removeAt(i);
        }
      }
    }
  }

  List<int> _normalizeRestPerSetValues(List<int> rawValues) {
    if (_sets <= 0) return [];
    if (rawValues.isEmpty) {
      return List<int>.filled(_sets, _restSeconds);
    }

    final normalized = rawValues.map((v) => v < 0 ? 0 : v).toList();
    if (normalized.length < _sets) {
      final fallback = normalized.isNotEmpty ? normalized.last : _restSeconds;
      normalized.addAll(List<int>.filled(_sets - normalized.length, fallback));
    } else if (normalized.length > _sets) {
      normalized.removeRange(_sets, normalized.length);
    }
    return normalized;
  }

  void _initializeRestControllers([List<int>? values]) {
    final restValues = _normalizeRestPerSetValues(
      values ?? List<int>.filled(_sets, _globalRestSeconds),
    );
    _restControllers = List.generate(
      _sets,
      (index) => TextEditingController(text: restValues[index].toString()),
    );
  }

  void _updateRestControllers() {
    if (_sets <= 0 || _sets > 20) return;

    if (_sets > _restControllers.length) {
      final fallback = _restControllers.isNotEmpty
          ? int.tryParse(_restControllers.last.text.trim()) ??
                _globalRestSeconds
          : _globalRestSeconds;
      for (int i = _restControllers.length; i < _sets; i++) {
        _restControllers.add(TextEditingController(text: fallback.toString()));
      }
      return;
    }

    for (int i = _restControllers.length - 1; i >= _sets; i--) {
      _restControllers[i].dispose();
      _restControllers.removeAt(i);
    }
  }

  void _applyUniformRestToAllSets(int seconds) {
    for (final controller in _restControllers) {
      controller.text = seconds.toString();
    }
  }

  void _applyUniformRepsToAllSets(String repsValue) {
    for (final controller in _repsControllers) {
      controller.text = repsValue;
    }
  }

  void _initializeRepsControllersWithList(List<String> repsList) {
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    _repsControllers = List.generate(
      _sets,
      (index) => TextEditingController(
        text: index < repsList.length
            ? repsList[index]
            : (repsList.isNotEmpty ? repsList.last : '10'),
      ),
    );
  }

  int? _parseBoundedInt({
    required String rawValue,
    required String fieldLabel,
    required int min,
    required int max,
  }) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      _showInputError('$fieldLabel non puo essere vuoto.');
      return null;
    }

    final parsed = int.tryParse(value);
    if (parsed == null) {
      _showInputError('$fieldLabel deve essere un numero intero.');
      return null;
    }

    if (parsed < min || parsed > max) {
      _showInputError('$fieldLabel deve essere tra $min e $max.');
      return null;
    }

    return parsed;
  }

  String? _parseCardioDuration(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      _showInputError('La durata non puo essere vuota.');
      return null;
    }

    int totalSeconds;
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length != 2) {
        _showInputError('Usa un formato durata valido, ad esempio 1:30.');
        return null;
      }

      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null || seconds < 0 || seconds > 59) {
        _showInputError('Usa un formato durata valido, ad esempio 1:30.');
        return null;
      }
      totalSeconds = (minutes * 60) + seconds;
    } else {
      final seconds = int.tryParse(value);
      if (seconds == null) {
        _showInputError('La durata deve essere in secondi o in formato m:ss.');
        return null;
      }
      totalSeconds = seconds;
    }

    if (totalSeconds < 1 || totalSeconds > 7200) {
      _showInputError('La durata deve essere tra 1 secondo e 120 minuti.');
      return null;
    }

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showInputError(String message) {
    HapticService.errorPattern();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valore non valido'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFieldSaved(String message) {
    if (!mounted) return;
    HapticService.lightTap();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
        backgroundColor: CleanTheme.accentGreen,
      ),
    );
  }

  void _saveCustomSets() {
    FocusScope.of(context).unfocus();
    final parsedSets = _parseBoundedInt(
      rawValue: _customSetsController.text,
      fieldLabel: 'Le serie',
      min: 1,
      max: 20,
    );
    if (parsedSets == null) return;

    setState(() {
      _sets = parsedSets;
      _customSetsController.text = parsedSets.toString();
      _updateRepsControllers();
      _updateRestControllers();
      if (_isUniformReps) {
        _applyUniformRepsToAllSets(_globalReps);
      }
      if (_isUniformRest) {
        _applyUniformRestToAllSets(_globalRestSeconds);
      }
    });
    _showFieldSaved('Serie salvate');
  }

  void _changeSetCountBy(int delta) {
    final nextSets = (_sets + delta).clamp(1, 20);
    if (nextSets == _sets) return;

    setState(() {
      _sets = nextSets;
      _customSetsController.text = nextSets.toString();
      _updateRepsControllers();
      _updateRestControllers();
      if (_isUniformReps) {
        _applyUniformRepsToAllSets(_globalReps);
      }
      if (_isUniformRest) {
        _applyUniformRestToAllSets(_globalRestSeconds);
      }
    });
    HapticService.selectionClick();
  }

  void _saveCustomTarget() {
    FocusScope.of(context).unfocus();
    final isCardio = _exerciseType == 'cardio';

    if (isCardio) {
      final parsedDuration = _parseCardioDuration(_customTargetController.text);
      if (parsedDuration == null) return;

      setState(() {
        _isUniformReps = true;
        _globalReps = parsedDuration;
        _customTargetController.text = parsedDuration;
        _updateRepsControllers();
        _applyUniformRepsToAllSets(parsedDuration);
      });
      _showFieldSaved('Durata salvata');
      return;
    }

    final parsedReps = _parseBoundedInt(
      rawValue: _customTargetController.text,
      fieldLabel: 'Le ripetizioni',
      min: 1,
      max: 999,
    );
    if (parsedReps == null) return;

    setState(() {
      _isUniformReps = true;
      _globalReps = parsedReps.toString();
      _customTargetController.text = parsedReps.toString();
      _updateRepsControllers();
      _applyUniformRepsToAllSets(parsedReps.toString());
    });
    _showFieldSaved('Ripetizioni salvate');
  }

  void _saveCustomRest() {
    FocusScope.of(context).unfocus();
    final parsedRest = _parseBoundedInt(
      rawValue: _customRestController.text,
      fieldLabel: 'Il recupero',
      min: 0,
      max: 600,
    );
    if (parsedRest == null) return;

    setState(() {
      _restSeconds = parsedRest;
      _globalRestSeconds = parsedRest;
      _isUniformRest = true;
      _customRestController.text = parsedRest.toString();
      _updateRestControllers();
      _applyUniformRestToAllSets(parsedRest);
    });
    _showFieldSaved('Recupero salvato');
  }

  @override
  void dispose() {
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    for (var controller in _restControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    _customSetsController.dispose();
    _customTargetController.dispose();
    _customRestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: CleanTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Elegant Header
          _buildSheetHeader(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // HYPER-FAST: One-Tap Patterns
                  _buildHyperShortcuts(),

                  const SizedBox(height: 32),

                  // Tactile Section: Sets
                  _buildSetSelectorGrid(),

                  const SizedBox(height: 32),

                  // Tactile Section: Reps / Time
                  _buildRepsSelectorGrid(),

                  const SizedBox(height: 32),

                  // Rest Period (Haptic Pills)
                  _buildRestQuickPills(),

                  const SizedBox(height: 32),

                  // Phase & Type (Simplified)
                  _buildCategorizationSection(),

                  const SizedBox(height: 32),

                  // Notes (Optional)
                  _buildNotesInput(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Action Button
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONFIGURA ESERCIZIO",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: CleanTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.exercise.exercise.name,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              backgroundColor: CleanTheme.surfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHyperShortcuts() {
    final isCardio = _exerciseType == 'cardio';

    final shortcuts = isCardio
        ? [
            {'label': '5 min', 'sets': 1, 'reps': '5:00'},
            {'label': '10 min', 'sets': 1, 'reps': '10:00'},
            {'label': '15 min', 'sets': 1, 'reps': '15:00'},
            {'label': '20 min', 'sets': 1, 'reps': '20:00'},
            {'label': '30 min', 'sets': 1, 'reps': '30:00'},
            {'label': '3x30s', 'sets': 3, 'reps': '0:30'},
            {'label': '3x1m', 'sets': 3, 'reps': '1:00'},
          ]
        : [
            {'label': '3 x 10', 'sets': 3, 'reps': '10'},
            {'label': '3 x 12', 'sets': 3, 'reps': '12'},
            {'label': '3 x 15', 'sets': 3, 'reps': '15'},
            {'label': '3 x 8', 'sets': 3, 'reps': '8'},
            {'label': '4 x 8', 'sets': 4, 'reps': '8'},
            {'label': '4 x 10', 'sets': 4, 'reps': '10'},
            {'label': '4 x 12', 'sets': 4, 'reps': '12'},
            {'label': '5 x 5', 'sets': 5, 'reps': '5'},
            {'label': '2 x 12', 'sets': 2, 'reps': '12'},
            {'label': 'Piramide (12-10-8-6)', 'sets': 4, 'reps': '12,10,8,6'},
            {'label': 'Inversa (6-8-10-12)', 'sets': 4, 'reps': '6,8,10,12'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer("ONE-TAP SETUP", "Configurazione istantanea"),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: shortcuts.map((s) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _sets = s['sets'] as int;
                    _customSetsController.text = _sets.toString();
                    _updateRestControllers();
                    if (_isUniformRest) {
                      _applyUniformRestToAllSets(_globalRestSeconds);
                    }
                    final repsValue = s['reps'] as String;

                    if (repsValue.contains(',')) {
                      _isUniformReps = false;
                      _customTargetController.clear();
                      final repsList = repsValue
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                      _initializeRepsControllersWithList(repsList);
                      _globalReps = repsList.first;
                    } else {
                      _isUniformReps = true;
                      _globalReps = repsValue;
                      _customTargetController.text = repsValue;
                      _updateRepsControllers();
                    }
                    HapticService.selectionClick();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [CleanTheme.primaryColor, CleanTheme.steelDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    s['label'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSetSelectorGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer("SERIE", "Seleziona il numero di set"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CleanTheme.borderSecondary),
          ),
          child: Row(
            children: [
              _buildSetStepButton(
                icon: Icons.remove_rounded,
                onTap: _sets > 1 ? () => _changeSetCountBy(-1) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_sets',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _sets == 1 ? 'serie' : 'serie',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSetStepButton(
                icon: Icons.add_rounded,
                onTap: _sets < 20 ? () => _changeSetCountBy(1) : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(10, (index) {
            final val = index + 1;
            final isSelected = _sets == val;
            return _buildTactileItem(
              label: val.toString(),
              isSelected: isSelected,
              onTap: () => setState(() {
                _sets = val;
                _customSetsController.text = val.toString();
                _updateRepsControllers();
                _updateRestControllers();
                if (_isUniformReps) {
                  _applyUniformRepsToAllSets(_globalReps);
                }
                if (_isUniformRest) {
                  _applyUniformRestToAllSets(_globalRestSeconds);
                }
              }),
            );
          }),
        ),
        const SizedBox(height: 16),
        _buildCustomInputField(
          label: 'Serie personalizzate',
          hint: '1-20',
          controller: _customSetsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {},
          onSavePressed: _saveCustomSets,
        ),
      ],
    );
  }

  Widget _buildSetStepButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null
              ? CleanTheme.chromeSubtle
              : CleanTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null
                ? CleanTheme.borderSecondary
                : CleanTheme.primaryColor.withValues(alpha: 0.22),
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? CleanTheme.textTertiary
              : CleanTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRepsSelectorGrid() {
    final isCardio = _exerciseType == 'cardio';
    final List<String> options = isCardio
        ? [
            '0:30',
            '0:45',
            '1:00',
            '2:00',
            '3:00',
            '5:00',
            '10:00',
            '15:00',
            '20:00',
            '30:00',
            '45:00',
            '60:00',
          ]
        : [
            '5',
            '6',
            '8',
            '10',
            '12',
            '15',
            '18',
            '20',
            '25',
            '30',
            '40',
            'Cedimento',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer(
          isCardio ? "DURATA" : "RIPETIZIONI",
          isCardio ? "Tempo per set" : "Target per set",
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final val = options[index];
            final isSelected = _globalReps == val;
            return _buildTactileItem(
              label: val,
              isSelected: isSelected,
              onTap: () => setState(() {
                _globalReps = val;
                _isUniformReps = true;
                _customTargetController.text = val == 'Cedimento' ? '' : val;
                _updateRepsControllers();
                _applyUniformRepsToAllSets(
                  val == 'Cedimento' ? 'A cedimento' : val,
                );
                HapticService.selectionClick();
              }),
              compact: true,
            );
          },
        ),
        const SizedBox(height: 16),
        _buildCustomInputField(
          label: isCardio
              ? 'Durata personalizzata'
              : 'Ripetizioni personalizzate',
          hint: isCardio ? 'es. 90 o 1:30' : '1-999',
          controller: _customTargetController,
          keyboardType: isCardio
              ? TextInputType.datetime
              : TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              isCardio ? RegExp(r'[\d:]') : RegExp(r'\d'),
            ),
          ],
          onChanged: (_) {},
          onSavePressed: _saveCustomTarget,
        ),
        const SizedBox(height: 16),
        _buildModeSwitchRow(
          leftLabel: 'Uniforme',
          rightLabel: 'Per Serie',
          isRightActive: !_isUniformReps,
          onSelectLeft: () {
            setState(() {
              _isUniformReps = true;
              _updateRepsControllers();
              _applyUniformRepsToAllSets(_globalReps);
            });
          },
          onSelectRight: () {
            setState(() {
              _isUniformReps = false;
              _updateRepsControllers();
            });
          },
        ),
        if (!_isUniformReps) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: Column(
              children: List.generate(_sets, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _sets - 1 ? 0 : 10),
                  child: _buildPerSetInputRow(
                    label: 'Serie ${index + 1}',
                    controller: _repsControllers[index],
                    hintText: isCardio ? 'es. 1:30' : 'es. 10',
                    keyboardType: isCardio
                        ? TextInputType.datetime
                        : TextInputType.text,
                    inputFormatters: isCardio
                        ? [FilteringTextInputFormatter.allow(RegExp(r'[\d:]'))]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required ValueChanged<String> onChanged,
    VoidCallback? onSavePressed,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: (_) => onSavePressed?.call(),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
        suffixIcon: onSavePressed == null
            ? null
            : TextButton(
                onPressed: onSavePressed,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Salva',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ),
        filled: true,
        fillColor: CleanTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.primaryColor),
        ),
      ),
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
    );
  }

  Widget _buildTactileItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticService.lightTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: compact ? null : 60,
        height: compact ? null : 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? CleanTheme.primaryColor : CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderSecondary,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: label.length > 3 ? 12 : 18,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : CleanTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  // End of grids

  Widget _buildRestQuickPills() {
    final options = [15, 30, 45, 60, 90, 120, 180, 240, 300];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer("RECUPERO", "Secondi di riposo"),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((s) {
            final isSelected = _restSeconds == s;
            return GestureDetector(
              onTap: () => setState(() {
                _restSeconds = s;
                _globalRestSeconds = s;
                _isUniformRest = true;
                _customRestController.text = s.toString();
                _updateRestControllers();
                _applyUniformRestToAllSets(s);
                HapticService.selectionClick();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.primaryColor
                      : CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(100), // Pill shape
                  border: Border.all(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : CleanTheme.borderSecondary,
                  ),
                ),
                child: Text(
                  "${s}s",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : CleanTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildCustomInputField(
          label: 'Recupero personalizzato',
          hint: '0-600 secondi',
          controller: _customRestController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {},
          onSavePressed: _saveCustomRest,
        ),
        const SizedBox(height: 16),
        _buildModeSwitchRow(
          leftLabel: 'Uniforme',
          rightLabel: 'Per Serie',
          isRightActive: !_isUniformRest,
          onSelectLeft: () {
            setState(() {
              _isUniformRest = true;
              _updateRestControllers();
              _applyUniformRestToAllSets(_globalRestSeconds);
            });
          },
          onSelectRight: () {
            setState(() {
              _isUniformRest = false;
              _updateRestControllers();
            });
          },
        ),
        if (!_isUniformRest) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: Column(
              children: List.generate(_sets, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _sets - 1 ? 0 : 10),
                  child: _buildPerSetInputRow(
                    label: 'Serie ${index + 1}',
                    controller: _restControllers[index],
                    hintText: 'secondi',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModeSwitchRow({
    required String leftLabel,
    required String rightLabel,
    required bool isRightActive,
    required VoidCallback onSelectLeft,
    required VoidCallback onSelectRight,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTactileItem(
            label: leftLabel,
            isSelected: !isRightActive,
            onTap: onSelectLeft,
            compact: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTactileItem(
            label: rightLabel,
            isSelected: isRightActive,
            onTap: onSelectRight,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPerSetInputRow({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: GoogleFonts.inter(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CleanTheme.borderSecondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CleanTheme.borderSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: CleanTheme.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer("STRUTTURA", "Fase e Tipologia"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTagSelector(
                label: "FASE",
                options: {
                  'warmup': 'Riscaldamento',
                  'main': 'Allenamento',
                  'post_workout': 'Defaticamento',
                },
                value: _position,
                onChanged: (v) => setState(() => _position = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTagSelector(
          label: "OBIETTIVO",
          options: {
            'strength': 'Forza/Ipertrofia',
            'cardio': 'Cardio/Resistenza',
            'mobility': 'Mobilità/Flex',
          },
          value: _exerciseType,
          onChanged: (v) => setState(() => _exerciseType = v),
        ),
      ],
    );
  }

  Widget _buildTagSelector({
    required String label,
    required Map<String, String> options,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final isSelected = e.key == value;
            return GestureDetector(
              onTap: () => onChanged(e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                      : CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : CleanTheme.borderSecondary,
                  ),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : CleanTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigHedaer("NOTE", "Istruzioni personali"),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: GoogleFonts.inter(color: CleanTheme.textPrimary),
          decoration: InputDecoration(
            hintText: "es. Focus sulla contrazione...",
            hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
            filled: true,
            fillColor: CleanTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: CleanTheme.borderSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Delete button (frictionless)
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRemove();
            },
            icon: const Icon(Icons.delete_outline, color: CleanTheme.accentRed),
            style: IconButton.styleFrom(
              backgroundColor: CleanTheme.accentRed.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saveExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                  foregroundColor: CleanTheme.textOnDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  "CONFERMA",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExercise() async {
    final parsedSets = _parseBoundedInt(
      rawValue: _customSetsController.text,
      fieldLabel: 'Le serie',
      min: 1,
      max: 20,
    );
    if (parsedSets == null) return;

    _sets = parsedSets;
    _updateRepsControllers();
    _updateRestControllers();

    String combinedReps;
    final isCardio = _exerciseType == 'cardio';

    if (!_isUniformReps) {
      final parsedValues = <String>[];
      for (int i = 0; i < _repsControllers.length; i++) {
        final rawValue = _repsControllers[i].text.trim();
        if (isCardio) {
          final parsedDuration = _parseCardioDuration(rawValue);
          if (parsedDuration == null) return;
          parsedValues.add(parsedDuration);
        } else {
          if (rawValue == 'Cedimento' || rawValue == 'A cedimento') {
            parsedValues.add('A cedimento');
            continue;
          }

          final parsedReps = _parseBoundedInt(
            rawValue: rawValue,
            fieldLabel: 'Le ripetizioni della serie ${i + 1}',
            min: 1,
            max: 999,
          );
          if (parsedReps == null) return;
          parsedValues.add(parsedReps.toString());
        }
      }
      combinedReps = parsedValues.join(', ');
    } else if (isCardio) {
      final parsedDuration = _parseCardioDuration(
        _customTargetController.text.trim().isNotEmpty
            ? _customTargetController.text
            : _globalReps,
      );
      if (parsedDuration == null) return;
      combinedReps = parsedDuration;
      _globalReps = parsedDuration;
      _customTargetController.text = parsedDuration;
    } else {
      final rawTarget = _customTargetController.text.trim().isNotEmpty
          ? _customTargetController.text.trim()
          : _globalReps;

      if (rawTarget == 'Cedimento' || rawTarget == 'A cedimento') {
        combinedReps = 'A cedimento';
      } else {
        final parsedReps = _parseBoundedInt(
          rawValue: rawTarget,
          fieldLabel: 'Le ripetizioni',
          min: 1,
          max: 999,
        );
        if (parsedReps == null) return;
        combinedReps = parsedReps.toString();
        _globalReps = combinedReps;
        _customTargetController.text = combinedReps;
      }
    }

    List<int> restPerSetValues;
    if (_isUniformRest) {
      final restSource = _customRestController.text.trim().isNotEmpty
          ? _customRestController.text.trim()
          : _globalRestSeconds.toString();
      final parsedRest = _parseBoundedInt(
        rawValue: restSource,
        fieldLabel: 'Il recupero',
        min: 0,
        max: 600,
      );
      if (parsedRest == null) return;

      _restSeconds = parsedRest;
      _globalRestSeconds = parsedRest;
      _customRestController.text = parsedRest.toString();
      restPerSetValues = List<int>.filled(parsedSets, parsedRest);
      _applyUniformRestToAllSets(parsedRest);
    } else {
      restPerSetValues = <int>[];
      for (int i = 0; i < _restControllers.length; i++) {
        final parsedRest = _parseBoundedInt(
          rawValue: _restControllers[i].text,
          fieldLabel: 'Il recupero della serie ${i + 1}',
          min: 0,
          max: 600,
        );
        if (parsedRest == null) return;
        restPerSetValues.add(parsedRest);
      }

      if (restPerSetValues.isEmpty) {
        _showInputError('Inserisci almeno un recupero.');
        return;
      }

      _restSeconds = restPerSetValues.first;
      _globalRestSeconds = _restSeconds;
      _customRestController.text = _restSeconds.toString();
    }

    final updated = _LocalExercise(
      id: widget.exercise.id,
      exercise: widget.exercise.exercise,
      sets: parsedSets,
      reps: combinedReps.isNotEmpty ? combinedReps : '10',
      restSeconds: _restSeconds,
      restSecondsPerSet: restPerSetValues,
      exerciseType: _exerciseType,
      position: _position,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Widget _buildConfigHedaer(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
