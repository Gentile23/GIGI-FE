import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool get isEditing => widget.existingPlan != null;
  late QuotaService _quotaService;

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
              exercise: e.exercise,
              sets: e.sets,
              reps: e.reps,
              restSeconds: e.restSeconds,
              notes: e.notes,
            ),
          )
          .toList();
    }
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
          backgroundColor: Colors.orange,
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
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Errore nel salvataggio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _addExercises() async {
    final selectedExercises = await Navigator.push<List<Exercise>>(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseSearchScreen()),
    );

    if (selectedExercises != null && selectedExercises.isNotEmpty) {
      setState(() {
        for (final exercise in selectedExercises) {
          // Avoid duplicates
          if (!_exercises.any((e) => e.exercise.id == exercise.id)) {
            _exercises.add(_LocalExercise(exercise: exercise));
          }
        }
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _editExercise(int index) async {
    final exercise = _exercises[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditExerciseSheet(
        exercise: exercise,
        onSave: (updated) {
          setState(() {
            _exercises[index] = updated;
          });
        },
      ),
    );
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
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
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CleanTheme.primaryColor,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.save,
                    style: GoogleFonts.outfit(
                      color: CleanTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form fields
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.workoutNameLabel,
                        labelStyle: GoogleFonts.outfit(
                          color: CleanTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: CleanTheme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: CleanTheme.primaryColor,
                          ),
                        ),
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
                    const SizedBox(height: 12),
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.descriptionOptional,
                        labelStyle: GoogleFonts.outfit(
                          color: CleanTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: CleanTheme.cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Exercises header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.exercisesCount(0).split(' ')[1]} (${_exercises.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addExercises,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        AppLocalizations.of(context)!.add,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: CleanTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Exercises list
              Expanded(
                child: _exercises.isEmpty
                    ? _buildEmptyExercises()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _exercises.length,
                        onReorder: _reorderExercises,
                        itemBuilder: (context, index) {
                          return _buildExerciseItem(index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExercises() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noExercisesAdded,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tapAddSearch,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(int index) {
    final exercise = _exercises[index];

    return Container(
      key: ValueKey(exercise.exercise.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: GoogleFonts.outfit(
                color: CleanTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          exercise.exercise.name,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CleanTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          '${exercise.sets} x ${exercise.reps} • ${exercise.restSeconds}s rest',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: CleanTheme.textSecondary,
              onPressed: () => _editExercise(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red[400],
              onPressed: () => _removeExercise(index),
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Local class to track exercise with its parameters
class _LocalExercise {
  final Exercise exercise;
  int sets;
  String reps;
  int restSeconds;
  String? notes;

  _LocalExercise({
    required this.exercise,
    this.sets = 3,
    this.reps = '10',
    this.restSeconds = 60,
    this.notes,
  });
}

/// Bottom sheet for editing exercise parameters
class _EditExerciseSheet extends StatefulWidget {
  final _LocalExercise exercise;
  final Function(_LocalExercise) onSave;

  const _EditExerciseSheet({required this.exercise, required this.onSave});

  @override
  State<_EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<_EditExerciseSheet> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.exercise.sets.toString(),
    );
    _repsController = TextEditingController(text: widget.exercise.reps);
    _restController = TextEditingController(
      text: widget.exercise.restSeconds.toString(),
    );
    _notesController = TextEditingController(text: widget.exercise.notes ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              widget.exercise.exercise.name,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            // Fields row
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    AppLocalizations.of(context)!.sets,
                    _setsController,
                    AppLocalizations.of(context)!.numberLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    AppLocalizations.of(context)!.reps,
                    _repsController,
                    'es. 10 o 8-12',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    AppLocalizations.of(context)!.restSecondsLabel,
                    _restController,
                    AppLocalizations.of(context)!.seconds,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notes
            _buildField(
              AppLocalizations.of(context)!.notesOptional,
              _notesController,
              AppLocalizations.of(context)!.notesHint,
            ),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final updated = _LocalExercise(
                    exercise: widget.exercise.exercise,
                    sets: int.tryParse(_setsController.text) ?? 3,
                    reps: _repsController.text.isNotEmpty
                        ? _repsController.text
                        : '10',
                    restSeconds: int.tryParse(_restController.text) ?? 60,
                    notes: _notesController.text.isNotEmpty
                        ? _notesController.text
                        : null,
                  );
                  widget.onSave(updated);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.saveChanges,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: CleanTheme.textTertiary),
            filled: true,
            fillColor: CleanTheme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: label.contains('Note')
              ? TextInputType.text
              : TextInputType.number,
        ),
      ],
    );
  }
}
