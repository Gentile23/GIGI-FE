import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/services/exercise_service.dart';
import '../../../data/services/api_client.dart';
import '../../screens/workout/exercise_detail_screen.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../../core/services/haptic_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';

/// Screen for searching and selecting exercises from the database
class ExerciseSearchScreen extends StatefulWidget {
  final bool isSelectionMode;

  const ExerciseSearchScreen({super.key, this.isSelectionMode = true});

  @override
  State<ExerciseSearchScreen> createState() => _ExerciseSearchScreenState();
}

// Italian to English mapping for muscle groups (reverse of _translateFilterOption)
String? _toEnglishMuscleGroup(String? italianName) {
  if (italianName == null) return null;
  const map = {
    'Petto': 'Chest',
    'Dorso': 'Back',
    'Spalle': 'Shoulders',
    'Bicipiti': 'Biceps',
    'Tricipiti': 'Triceps',
    'Addominali': 'Abs',
    'Gambe': 'Legs',
    'Avambracci': 'Forearms',
    'Trapezi': 'Traps',
    'Obliqui': 'Obliques',
    'Quadricipiti': 'Quads',
    'Femorali': 'Hamstrings',
    'Glutei': 'Glutes',
    'Polpacci': 'Calves',
  };
  return map[italianName] ?? italianName;
}

// Italian to English mapping for equipment
String? _toEnglishEquipment(String? italianName) {
  if (italianName == null) return null;
  const map = {
    'Corpo Libero': 'Bodyweight',
    'Manubri': 'Dumbbell',
    'Bilanciere': 'Barbell',
    'Macchinario': 'Machine',
    'Cavi': 'Cables',
    'Kettlebell': 'Kettlebell',
    'Elastico': 'Resistance Band',
    'Sbarra Trazioni': 'Pull-up Bar',
    'Panca': 'Bench',
  };
  return map[italianName] ?? italianName;
}

class _ExerciseSearchScreenState extends State<ExerciseSearchScreen> {
  late ExerciseService _exerciseService;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  final Map<String, Exercise> _selectedExercises = {};

  String? _selectedMuscleGroup;
  String? _selectedEquipment;
  String? _selectedDifficulty;
  String? _selectedType;

  bool _isLoading = true;
  String? _error;

  final List<String> _equipmentOptions = [
    'Bodyweight',
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cables',
    'Machine',
    'Resistance Band',
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _exerciseService.getExercises(
        muscleGroup: _toEnglishMuscleGroup(_selectedMuscleGroup),
        equipment: _toEnglishEquipment(_selectedEquipment),
        difficulty: _selectedDifficulty,
        exerciseType: _selectedType,
        search: _searchController.text,
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _allExercises = result['exercises'] as List<Exercise>;
            _filteredExercises = _filterExercises(_allExercises);
          } else {
            _error = result['message'] as String?;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Si è verificato un errore inatteso. Riprova.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Italian to English mapping for search
  final Map<String, List<String>> _italianMappings = {
    'panca': ['bench'],
    'spinte': ['press', 'push'],
    'croci': ['fly'],
    'stacco': ['deadlift'],
    'rematore': ['row', 'rowing', 'tirage'],
    'trazioni': ['pull up', 'chin up', 'lat pull', 'pulldown'],
    'flessioni': ['push up'],
    'affondi': ['lunge'],
    'alzate': ['raise'],
    'estensioni': ['extension'],
    'curl': ['curl'],
    'presse': ['press'],
    'cavo': ['cable', 'cables', 'pulley', 'poulie'],
    'cav': ['cable'],
    'cavi': ['cable', 'cables', 'pulley', 'poulie'],
    'pulley': [
      'cable',
      'cables',
      'poulie',
      'puleggia',
      'row',
      'rowing',
      'tirage',
    ],
    'puleggia': ['cable', 'cables', 'pulley', 'poulie'],
    'poulie': ['cable', 'cables', 'pulley'],
    'lat machine': ['lat pulldown', 'pulldown', 'tirage vertical'],
    'latmachine': ['lat pulldown', 'pulldown', 'tirage vertical'],
    'tirata': ['row', 'rowing', 'tirage', 'pulldown'],
    'tiraggio': ['row', 'rowing', 'tirage', 'pulldown'],
    'manubri': ['dumbbell'],
    'bilanciere': ['barbell'],
    'sbarra': ['bar'],
    'corpo libero': ['bodyweight'],
    'petto': ['chest', 'pectoral'],
    'dorso': ['back', 'lat'],
    'schiena': ['back'],
    'gambe': ['leg', 'quad', 'hamstring', 'calf'],
    'spalle': ['shoulder', 'deltoid'],
    'braccia': ['arm', 'bicep', 'tricep'],
    'tricipiti': ['triceps'],
    'bicipiti': ['biceps'],
    'addominali': ['abs', 'core', 'crunch', 'plank'],
    'glutei': ['glute'],
    'polpacci': ['calf'],
    'cardio': ['cardio', 'run', 'jump'],
    'mobilità': ['mobility', 'stretch', 'yoga', 'foam'],
  };

  void _applySearch() {
    setState(() {
      _filteredExercises = _filterExercises(_allExercises);
    });
  }

  List<Exercise> _filterExercises(List<Exercise> exercises) {
    final rawQuery = _searchController.text.toLowerCase().trim();

    if (rawQuery.isEmpty) {
      return List.from(exercises);
    }

    // Expand query with English terms if Italian keywords are found
    final searchTerms = [rawQuery];
    _italianMappings.forEach((italian, englishTerms) {
      if (rawQuery.contains(italian)) {
        searchTerms.addAll(englishTerms);
      }
    });

    return exercises.where((exercise) {
      final searchableName = exercise.name.toLowerCase();
      final italianName = exercise.nameIt?.toLowerCase() ?? '';
      final description = exercise.description.toLowerCase();

      // Check exact name match first
      if (searchableName.contains(rawQuery) ||
          italianName.contains(rawQuery) ||
          description.contains(rawQuery)) {
        return true;
      }

      // Check against expanded terms
      return searchTerms.any((term) {
        final t = term.toLowerCase();
        return searchableName.contains(t) ||
            italianName.contains(t) ||
            description.contains(t) ||
            exercise.muscleGroups.any((mg) => mg.toLowerCase().contains(t)) ||
            exercise.secondaryMuscleGroups.any(
              (mg) => mg.toLowerCase().contains(t),
            ) ||
            exercise.equipment.any((eq) => eq.toLowerCase().contains(t));
      });
    }).toList();
  }

  void _onSearchChanged(String _) {
    if (_searchController.text.trim().isNotEmpty &&
        _selectedMuscleGroup != null) {
      setState(() {
        _selectedMuscleGroup = null;
        _filteredExercises = _filterExercises(_allExercises);
      });
    } else {
      _applySearch();
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadExercises);
  }

  void _toggleSelection(Exercise exercise) {
    setState(() {
      if (_selectedExercises.containsKey(exercise.id)) {
        _selectedExercises.remove(exercise.id);
      } else {
        _selectedExercises[exercise.id] = exercise;
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedExercises.values.toList());
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
        muscleGroups: const [
          'Petto',
          'Dorso',
          'Spalle',
          'Bicipiti',
          'Tricipiti',
          'Addominali',
          'Gambe',
          'Avambracci',
          'Trapezi',
          'Obliqui',
          'Quadricipiti',
          'Femorali',
          'Glutei',
          'Polpacci',
        ],
        equipmentOptions: _equipmentOptions,
        difficultyOptions: _difficultyOptions,
        selectedType: _selectedType,
        onApply: (muscleGroup, equipment, difficulty, type) {
          setState(() {
            _selectedMuscleGroup = muscleGroup;
            _selectedEquipment = equipment;
            _selectedDifficulty = difficulty;
            _selectedType = type;
          });
          _loadExercises();
        },
        onClear: () {
          setState(() {
            _selectedMuscleGroup = null;
            _selectedEquipment = null;
            _selectedDifficulty = null;
            _selectedType = null;
          });
          _loadExercises();
        },
      ),
    );
  }

  Widget _buildTypeGrid() {
    final List<Map<String, dynamic>> typeCategories = [
      {'id': 'strength', 'label': 'Workout', 'icon': Icons.fitness_center},
      {'id': 'cardio', 'label': 'Cardio', 'icon': Icons.bolt},
      {'id': 'warmup', 'label': 'Mobilità', 'icon': Icons.self_improvement},
    ];

    return Container(
      height: 90,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: typeCategories.map((cat) {
          final catId = cat['id'] as String;
          final isSelected = _selectedType == catId;
          final index = typeCategories.indexOf(cat);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == typeCategories.length - 1 ? 0 : 12,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticService.lightTap();
                  setState(() {
                    if (_selectedType == catId) {
                      _selectedType = null;
                      _selectedEquipment = null;
                    } else {
                      _selectedType = catId;
                      _selectedEquipment = null;
                    }
                    // Clear muscle group when type changes
                    _selectedMuscleGroup = null;
                  });
                  _loadExercises();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : CleanTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? CleanTheme.primaryColor
                          : CleanTheme.borderSecondary,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : CleanTheme.textSecondary,
                        size: 26,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['label'] as String,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : CleanTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMuscleGroupGrid() {
    if (_selectedType != 'strength') return const SizedBox.shrink();

    final List<Map<String, dynamic>> muscleCategories = [
      {'id': 'Petto', 'label': 'Petto', 'icon': Icons.sports_gymnastics},
      {'id': 'Dorso', 'label': 'Dorso', 'icon': Icons.airline_stops},
      {'id': 'Spalle', 'label': 'Spalle', 'icon': Icons.accessibility_new},
      {'id': 'Bicipiti', 'label': 'Bicipiti', 'icon': Icons.fitness_center},
      {'id': 'Tricipiti', 'label': 'Tricipiti', 'icon': Icons.fitness_center},
      {'id': 'Addominali', 'label': 'Addominali', 'icon': Icons.grid_view},
      {'id': 'Gambe', 'label': 'Gambe', 'icon': Icons.directions_run},
    ];

    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              "GRUPPO MUSCOLARE",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: CleanTheme.textTertiary,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: muscleCategories.length,
              itemBuilder: (context, index) {
                final cat = muscleCategories[index];
                final catId = cat['id'] as String;
                final isSelected = _selectedMuscleGroup == catId;

                return GestureDetector(
                  onTap: () {
                    HapticService.lightTap();
                    setState(() {
                      _selectedMuscleGroup = isSelected ? null : catId;
                    });
                    _loadExercises();
                  },
                  child:
                      AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CleanTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? CleanTheme.primaryColor
                                    : CleanTheme.borderSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat['label'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? CleanTheme.primaryColor
                                        : CleanTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideX(begin: 0.2, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: CleanTheme.backgroundColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                AppLocalizations.of(context)!.searchExercises,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.5,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            actions: [
              if (widget.isSelectionMode && _selectedExercises.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: _confirmSelection,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppLocalizations.of(context)!.add} (${_selectedExercises.length})',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Premium Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: CleanTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        hintStyle: GoogleFonts.outfit(
                          color: CleanTheme.textTertiary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: CleanTheme.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: CleanTheme.textSecondary,
                                onPressed: () {
                                  _searchController.clear();
                                  _loadExercises();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Two-Tier Categories
                  _buildTypeGrid(),
                  _buildMuscleGroupGrid(),

                  // Secondary Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _showFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (_selectedEquipment != null ||
                                      _selectedDifficulty != null)
                                  ? CleanTheme.primaryColor.withValues(
                                      alpha: 0.1,
                                    )
                                  : CleanTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    (_selectedEquipment != null ||
                                        _selectedDifficulty != null)
                                    ? CleanTheme.primaryColor
                                    : CleanTheme.borderSecondary,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color:
                                      (_selectedEquipment != null ||
                                          _selectedDifficulty != null)
                                      ? CleanTheme.primaryColor
                                      : CleanTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Filtri Avanzati",
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        (_selectedEquipment != null ||
                                            _selectedDifficulty != null)
                                        ? CleanTheme.primaryColor
                                        : CleanTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildResultsSliver(),
        ],
      ),
    );
  }

  Widget _buildResultsSliver() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: CleanTheme.accentRed),
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
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredExercises.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: CleanTheme.textTertiary),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noExercisesFound,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.tryAdjustFilters,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final exercise = _filteredExercises[index];
          final isSelected = _selectedExercises.containsKey(exercise.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildExerciseItemRedesigned(exercise, isSelected),
          );
        }, childCount: _filteredExercises.length),
      ),
    );
  }

  Widget _buildExerciseItemRedesigned(Exercise exercise, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
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
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                transform: isSelected
                    ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
                    : Matrix4.identity(),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : CleanTheme.borderSecondary.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    // Always include the second shadow to allow for smooth lerping (prevents Web crash)
                    BoxShadow(
                      color: isSelected
                          ? CleanTheme.primaryColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      blurRadius: isSelected ? 15 : 0,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon Container with vibrancy
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    CleanTheme.primaryColor,
                                    CleanTheme.primaryColor.withValues(
                                      alpha: 0.8,
                                    ),
                                  ]
                                : [Colors.grey[100]!, Colors.grey[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected ? Icons.check : Icons.fitness_center,
                            color: isSelected
                                ? Colors.white
                                : CleanTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.localizedName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: CleanTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.muscleGroups.join(' • '),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Visual State Indicator
                      if (widget.isSelectionMode)
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.textTertiary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 400.ms),
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
  final String? selectedType;
  final Function(String?, String?, String?, String?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.selectedMuscleGroup,
    required this.selectedEquipment,
    required this.selectedDifficulty,
    required this.muscleGroups,
    required this.equipmentOptions,
    required this.difficultyOptions,
    this.selectedType,
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
  String? _type;

  @override
  void initState() {
    super.initState();
    _muscleGroup = widget.selectedMuscleGroup;
    _equipment = widget.selectedEquipment;
    _difficulty = widget.selectedDifficulty;
    _type = widget.selectedType;
  }

  // Muscle groups to exclude when cardio is selected
  static const _cardioExcludedMuscles = {
    'Petto',
    'Bicipiti',
    'Tricipiti',
    'Avambracci',
    'Trapezi',
    'Obliqui',
  };

  @override
  Widget build(BuildContext context) {
    // Filter muscle groups based on selected type
    final filteredMuscleGroups = _type == 'cardio'
        ? widget.muscleGroups
              .where((m) => !_cardioExcludedMuscles.contains(m))
              .toList()
        : widget.muscleGroups;

    // Filter equipment based on selected type
    final filteredEquipment = _type == 'cardio'
        ? ['Bodyweight', 'Machine']
        : _type == 'warmup'
        ? ['Bodyweight', 'Machine', 'Resistance Band']
        : widget.equipmentOptions;

    // Filter difficulty based on selected type
    final List<String> filteredDifficulty;
    final Map<String, String>? difficultyLabelOverrides;
    if (_type == 'cardio') {
      filteredDifficulty = ['Beginner', 'Intermediate'];
      difficultyLabelOverrides = {
        'Beginner': 'Principiante',
        'Intermediate': 'Avanzato',
      };
    } else if (_type == 'warmup') {
      filteredDifficulty = ['Beginner', 'Intermediate'];
      difficultyLabelOverrides = {'Intermediate': 'Avanzata'};
    } else {
      filteredDifficulty = widget.difficultyOptions;
      difficultyLabelOverrides = null;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Filtri Avanzati",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: CleanTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "Personalizza la tua ricerca",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    "GRUPPO MUSCOLARE",
                    filteredMuscleGroups,
                    _muscleGroup,
                    (val) => setState(() => _muscleGroup = val),
                    showMuscleVisual: true,
                  ),
                  const SizedBox(height: 32),
                  _buildFilterSection(
                    "ATTREZZATURA",
                    filteredEquipment,
                    _equipment,
                    (val) => setState(() => _equipment = val),
                  ),
                  const SizedBox(height: 32),
                  _buildFilterSection(
                    "DIFFICOLTÀ",
                    filteredDifficulty,
                    _difficulty,
                    (val) => setState(() => _difficulty = val),
                    labelOverrides: difficultyLabelOverrides,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Bottom Actions
          Container(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
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
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {
                      HapticService.lightTap();
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "RESET",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CleanTheme.accentRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.selectionClick();
                      widget.onApply(
                        _muscleGroup,
                        _equipment,
                        _difficulty,
                        _type,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "APPLICA",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _sectionIcon(String title) {
    switch (title) {
      case 'GRUPPO MUSCOLARE':
        return Icons.accessibility_new_rounded;
      case 'ATTREZZATURA':
        return Icons.fitness_center_rounded;
      case 'DIFFICOLTÀ':
        return Icons.speed_rounded;
      default:
        return Icons.tune_rounded;
    }
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String? selected,
    Function(String?) onSelect, {
    Map<String, String>? labelOverrides,
    bool showMuscleVisual = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _sectionIcon(title),
                size: 16,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: CleanTheme.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () {
                HapticService.lightTap();
                onSelect(isSelected ? null : option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: showMuscleVisual ? 14 : 18,
                  vertical: showMuscleVisual ? 10 : 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? CleanTheme.primaryColor
                        : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showMuscleVisual) ...[
                      SizedBox(
                        height: 48,
                        width: 36,
                        child: AnatomicalMuscleView(
                          muscleGroups: [_toEnglishMuscleGroup(option) ?? ''],
                          height: 48,
                          highlightColor: isSelected
                              ? CleanTheme.primaryColor
                              : const Color(0xFFFF0000),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (isSelected) ...[
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      labelOverrides?[option] ?? _translateFilterOption(option),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

String _translateFilterOption(String value) {
  final Map<String, String> map = {
    // Muscles
    'Chest': 'Petto',
    'Back': 'Dorso',
    'Shoulders': 'Spalle',
    'Biceps': 'Bicipiti',
    'Triceps': 'Tricipiti',
    'Forearms': 'Avambracci',
    'Traps': 'Trapezi',
    'Abs': 'Addominali',
    'Obliques': 'Obliqui',
    'Quads': 'Quadricipiti',
    'Hamstrings': 'Femorali',
    'Glutes': 'Glutei',
    'Calves': 'Polpacci',
    'Full Body': 'Total Body',
    // Difficulty
    'Beginner': 'Principiante',
    'Intermediate': 'Intermedio',
    'Advanced': 'Avanzato',
    // Type
    'strength': 'Workout',
    'cardio': 'Cardio',
    'warmup': 'Mobilità',
    // Equipment
    'None': 'Corpo Libero',
    'Bodyweight': 'Corpo Libero',
    'Dumbbell': 'Manubri',
    'Dumbbells': 'Manubri',
    'Barbell': 'Bilanciere',
    'Machine': 'Macchinario',
    'Cable': 'Cavo',
    'Kettlebell': 'Kettlebell',
    'Band': 'Elastico',
    'Resistance Band': 'Elastico',
    'Cables': 'Cavi',
    'Pull-up Bar': 'Sbarra Trazioni',
    'Bench': 'Panca',
  };
  return map[value] ?? value;
}
