import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/constants/muscle_groups.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/services/exercise_service.dart';
import '../../../data/services/api_client.dart';
import '../../screens/workout/exercise_detail_screen.dart';

/// Screen for searching and selecting exercises from the database
class ExerciseSearchScreen extends StatefulWidget {
  final bool isSelectionMode;

  const ExerciseSearchScreen({super.key, this.isSelectionMode = true});

  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  late ExerciseService _exerciseService;
  final _searchController = TextEditingController();

  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  final Set<String> _selectedExerciseIds = {};

  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  String? _selectedDifficulty;

  bool _isLoading = true;
  String? _error;

  final List<String> _equipmentOptions = [
    'Bodyweight',
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cable',
    'Machine',
    'Resistance Bands',
    'TRX',
    'Exercise Ball',
  ];

  final List<String> _difficultyOptions = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _exerciseService = ExerciseService(ApiClient());
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _exerciseService.getExercises(
      muscleGroup: _selectedMuscleGroup,
      equipment: _selectedEquipment,
      difficulty: _selectedDifficulty,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _allExercises = result['exercises'] as List<Exercise>;
          _applySearch();
        } else {
          _error = result['message'] as String?;
        }
      });
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = List.from(_allExercises);
      } else {
        _filteredExercises = _allExercises.where((exercise) {
          return exercise.name.toLowerCase().contains(query) ||
              exercise.muscleGroups.any(
                (mg) => mg.toLowerCase().contains(query),
              ) ||
              exercise.equipment.any((eq) => eq.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selectedExerciseIds.contains(exercise.id)) {
        _selectedExerciseIds.remove(exercise.id);
      } else {
        _selectedExerciseIds.add(exercise.id);
      }
    });
  }

  void _confirmSelection() {
    final selectedExercises = _allExercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();
    Navigator.pop(context, selectedExercises);
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        selectedMuscleGroup: _selectedMuscleGroup,
        selectedEquipment: _selectedEquipment,
        selectedDifficulty: _selectedDifficulty,
        muscleGroups: MuscleGroups.all,
        equipmentOptions: _equipmentOptions,
        difficultyOptions: _difficultyOptions,
        onApply: (muscleGroup, equipment, difficulty) {
          setState(() {
            _selectedMuscleGroup = muscleGroup;
            _selectedEquipment = equipment;
            _selectedDifficulty = difficulty;
          });
          _loadExercises();
        },
        onClear: () {
          setState(() {
            _selectedMuscleGroup = null;
            _selectedEquipment = null;
            _selectedDifficulty = null;
          });
          _loadExercises();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _selectedMuscleGroup != null ||
        _selectedEquipment != null ||
        _selectedDifficulty != null;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cerca Esercizi',
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
          if (widget.isSelectionMode && _selectedExerciseIds.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                'Aggiungi (${_selectedExerciseIds.length})',
                style: GoogleFonts.outfit(
                  color: CleanTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar and filters
          Container(
            padding: const EdgeInsets.all(16),
            color: CleanTheme.surfaceColor,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
                  onChanged: (_) => _applySearch(),
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome, muscolo o attrezzatura...',
                    hintStyle: GoogleFonts.outfit(
                      color: CleanTheme.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: CleanTheme.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            color: CleanTheme.textSecondary,
                            onPressed: () {
                              _searchController.clear();
                              _applySearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: CleanTheme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter button
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasActiveFilters
                              ? CleanTheme.primaryColor.withValues(alpha: 0.2)
                              : CleanTheme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasActiveFilters
                                ? CleanTheme.primaryColor
                                : Colors.grey[700]!,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: hasActiveFilters
                                  ? CleanTheme.primaryColor
                                  : CleanTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filtri',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: hasActiveFilters
                                    ? CleanTheme.primaryColor
                                    : CleanTheme.textSecondary,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _countActiveFilters().toString(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Active filter chips
                    if (_selectedMuscleGroup != null)
                      _buildFilterChip(_selectedMuscleGroup!, () {
                        setState(() => _selectedMuscleGroup = null);
                        _loadExercises();
                      }),
                    if (_selectedEquipment != null)
                      _buildFilterChip(_selectedEquipment!, () {
                        setState(() => _selectedEquipment = null);
                        _loadExercises();
                      }),
                  ],
                ),
              ],
            ),
          ),
          // Results
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  int _countActiveFilters() {
    int count = 0;
    if (_selectedMuscleGroup != null) count++;
    if (_selectedEquipment != null) count++;
    if (_selectedDifficulty != null) count++;
    return count;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: CleanTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: CleanTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.outfit(color: CleanTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExercises,
              style: ElevatedButton.styleFrom(
                backgroundColor: CleanTheme.primaryColor,
              ),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'Nessun esercizio trovato',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prova a modificare i filtri',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: CleanTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredExercises.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        final isSelected = _selectedExerciseIds.contains(exercise.id);

        return GestureDetector(
          onTap: () {
            if (widget.isSelectionMode) {
              _toggleSelection(exercise);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(
                    workoutExercise: WorkoutExercise(
                      exercise: exercise,
                      sets: 3,
                      reps: '10',
                      restSeconds: 60,
                    ),
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? CleanTheme.primaryColor.withValues(alpha: 0.15)
                  : CleanTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? CleanTheme.primaryColor : Colors.grey[700]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Selection indicator
                if (widget.isSelectionMode) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? CleanTheme.primaryColor
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : Colors.grey[600]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.muscleGroups.join(' • '),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: exercise.equipment.take(2).map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              eq,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: CleanTheme.textTertiary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  final String? selectedMuscleGroup;
  final String? selectedEquipment;
  final String? selectedDifficulty;
  final List<String> muscleGroups;
  final List<String> equipmentOptions;
  final List<String> difficultyOptions;
  final Function(String?, String?, String?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.selectedMuscleGroup,
    required this.selectedEquipment,
    required this.selectedDifficulty,
    required this.muscleGroups,
    required this.equipmentOptions,
    required this.difficultyOptions,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _muscleGroup;
  String? _equipment;
  String? _difficulty;

  @override
  void initState() {
    super.initState();
    _muscleGroup = widget.selectedMuscleGroup;
    _equipment = widget.selectedEquipment;
    _difficulty = widget.selectedDifficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtri',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Azzera',
                    style: GoogleFonts.outfit(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Filters
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muscle Group
                  _buildFilterSection(
                    'Gruppo Muscolare',
                    widget.muscleGroups,
                    _muscleGroup,
                    (value) => setState(() => _muscleGroup = value),
                  ),
                  const SizedBox(height: 20),
                  // Equipment
                  _buildFilterSection(
                    'Attrezzatura',
                    widget.equipmentOptions,
                    _equipment,
                    (value) => setState(() => _equipment = value),
                  ),
                  const SizedBox(height: 20),
                  // Difficulty
                  _buildFilterSection(
                    'Difficoltà',
                    widget.difficultyOptions,
                    _difficulty,
                    (value) => setState(() => _difficulty = value),
                  ),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_muscleGroup, _equipment, _difficulty);
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
                  'Applica Filtri',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selected,
    Function(String?) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onSelect(isSelected ? null : option),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.primaryColor
                      : CleanTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : Colors.grey[700]!,
                  ),
                ),
                child: Text(
                  option,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isSelected ? Colors.white : CleanTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
