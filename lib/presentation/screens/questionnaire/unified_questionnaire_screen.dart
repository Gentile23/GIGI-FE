import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/injury_model.dart';
import '../../../data/models/training_preferences_model.dart';
import '../main_screen.dart';

import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class UnifiedQuestionnaireScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const UnifiedQuestionnaireScreen({super.key, this.onComplete});

  @override
  State<UnifiedQuestionnaireScreen> createState() =>
      _UnifiedQuestionnaireScreenState();
}

class _UnifiedQuestionnaireScreenState
    extends State<UnifiedQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // We'll calculate total steps dynamically or just use a progress bar based on "known" remaining steps
  // For a truly linear feel with dynamic sections, a simple 0.0-1.0 progress might be better managed manually
  double _progress = 0.1;
  bool _isLoading = false;

  // --- State Variables ---

  // 1. Core Profile
  final Set<FitnessGoal> _selectedGoals = {FitnessGoal.wellness};
  ExperienceLevel? _selectedLevel = ExperienceLevel.beginner;
  int _weeklyFrequency = 3;
  TrainingLocation? _selectedLocation = TrainingLocation.gym;
  final Set<Equipment> _selectedEquipment = {};
  final Set<String> _selectedMachines = {};
  // Bodyweight sub-selection
  String? _selectedBodyweightType; // 'functional', 'calisthenics', 'pure'
  final Set<String> _selectedBodyweightEquipment =
      {}; // 'trx', 'bands', 'rings', 'bar', etc.
  double? _height;
  double? _weight;
  Gender? _selectedGender;
  BodyShape? _selectedBodyShape;
  WorkoutType? _selectedWorkoutType;
  int? _age;

  // 2. Injuries
  bool? _hasInjuries; // null = not asked yet
  final List<InjuryModel> _injuries = [];
  // Temp injury state
  InjuryCategory? _tempInjuryCategory;
  InjuryArea? _tempInjuryArea;
  InjurySeverity _tempInjurySeverity = InjurySeverity.moderate;
  InjuryTiming _tempInjuryTiming = InjuryTiming.current;
  String? _tempInjurySide; // 'left', 'right', 'bilateral', 'notApplicable'
  bool _tempInjuryOvercome = false;
  final TextEditingController _injuryNotesController = TextEditingController();
  final TextEditingController _painfulExercisesController =
      TextEditingController();

  // 3. Preferences
  TrainingSplit _selectedSplit = TrainingSplit.multifrequency;
  int _sessionDuration = 60;
  CardioPreference _cardioPreference = CardioPreference.none;
  MobilityPreference _mobilityPreference = MobilityPreference.postWorkout;
  final TextEditingController _prefNotesController = TextEditingController();

  // 4. Professional Trainer Fields (New)

  TimePreference? _timePreference;
  int _sleepHours = 8;
  RecoveryCapacity? _recoveryCapacity;
  NutritionApproach? _nutritionApproach;
  BodyFatPercentage? _bodyFatPercentage;
  TrainingHistory? _trainingHistory;

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      // 1. Core Profile
      if (user.goal != null) {
        _selectedGoals.clear();
        // Handle potential single goal string or mapping
        try {
          final goal = FitnessGoal.values.firstWhere(
            (e) => e.toString().split('.').last == user.goal,
          );
          _selectedGoals.add(goal);
        } catch (_) {
          // Fallback or ignore if invalid
        }
      }

      if (user.experienceLevel != null) {
        try {
          _selectedLevel = ExperienceLevel.values.firstWhere(
            (e) => e.toString().split('.').last == user.experienceLevel,
          );
        } catch (_) {}
      }

      if (user.weeklyFrequency != null) {
        _weeklyFrequency = user.weeklyFrequency!;
      }

      if (user.trainingLocation != null) {
        try {
          _selectedLocation = TrainingLocation.values.firstWhere(
            (e) => e.toString().split('.').last == user.trainingLocation,
          );
        } catch (_) {}
      }

      if (user.availableEquipment != null) {
        _selectedEquipment.clear();
        for (final eqString in user.availableEquipment!) {
          try {
            final eq = Equipment.values.firstWhere(
              (e) => e.toString().split('.').last == eqString,
            );
            _selectedEquipment.add(eq);
          } catch (_) {}
        }
      }

      if (user.height != null) _height = user.height;
      if (user.weight != null) _weight = user.weight;
      if (user.bodyShape != null) {
        try {
          _selectedBodyShape = BodyShape.values.firstWhere(
            (e) => e.toString().split('.').last == user.bodyShape,
          );
        } catch (_) {}
      }

      if (user.workoutType != null) {
        try {
          _selectedWorkoutType = WorkoutType.values.firstWhere(
            (e) => e.toString().split('.').last == user.workoutType,
          );
        } catch (_) {}
      }

      // 2. Preferences
      if (user.trainingSplit != null) {
        try {
          _selectedSplit = TrainingSplit.values.firstWhere(
            (e) => e.toString().split('.').last == user.trainingSplit,
          );
        } catch (_) {}
      }

      if (user.sessionDuration != null) {
        _sessionDuration = user.sessionDuration!;
      }

      // 4. Professional Trainer Fields

      if (user.timePreference != null) _timePreference = user.timePreference;
      if (user.sleepHours != null) _sleepHours = user.sleepHours!;
      if (user.recoveryCapacity != null) {
        _recoveryCapacity = user.recoveryCapacity;
      }
      if (user.nutritionApproach != null) {
        _nutritionApproach = user.nutritionApproach;
      }
      if (user.bodyFatPercentage != null) {
        _bodyFatPercentage = user.bodyFatPercentage;
      }

      if (user.cardioPreference != null) {
        try {
          _cardioPreference = CardioPreference.values.firstWhere(
            (e) => e.toString().split('.').last == user.cardioPreference,
          );
        } catch (_) {}
      }

      if (user.mobilityPreference != null) {
        try {
          _mobilityPreference = MobilityPreference.values.firstWhere(
            (e) => e.toString().split('.').last == user.mobilityPreference,
          );
        } catch (_) {}
      }

      if (user.trainingHistory != null) {
        _trainingHistory = user.trainingHistory;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _injuryNotesController.dispose();
    _painfulExercisesController.dispose();
    _prefNotesController.dispose();
    super.dispose();
  }

  // --- Navigation Logic ---

  void _nextPage() {
    // Chiude la tastiera quando si cambia pagina
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _updateProgress();
  }

  void _previousPage() {
    // Chiude la tastiera quando si cambia pagina
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _updateProgress();
  }

  void _updateProgress() {
    // Estimate progress based on current page index vs "total" pages
    // This is an approximation since the flow is dynamic
    setState(() {
      _currentStep = _pageController.page?.round() ?? 0;
      // Map pages to progress roughly
      // Total "Base" steps ~ 18 with restored Cardio/Mobility page.
      _progress = (_currentStep + 1) / 18.0;
      if (_progress > 1.0) _progress = 1.0;
    });
  }

  // --- Helper Methods ---

  // --- Core Actions ---

  void _addInjury() {
    if (_tempInjuryCategory != null && _tempInjuryArea != null) {
      final injury = InjuryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: _tempInjuryCategory!,
        area: _tempInjuryArea!,
        severity: _tempInjurySeverity,
        status: InjuryStatus.active,
        timing: _tempInjuryTiming,
        side: _tempInjurySide,
        isOvercome: _tempInjuryTiming == InjuryTiming.past
            ? _tempInjuryOvercome
            : null,
        painfulExercises: _painfulExercisesController.text.isNotEmpty
            ? _painfulExercisesController.text
            : null,
        notes: _injuryNotesController.text.isNotEmpty
            ? _injuryNotesController.text
            : null,
        reportedAt: DateTime.now(),
      );

      setState(() {
        _injuries.add(injury);
        // Reset temp state
        _tempInjuryCategory = null;
        _tempInjuryArea = null;
        _tempInjurySeverity = InjurySeverity.moderate;
        _tempInjuryTiming = InjuryTiming.current;
        _tempInjurySide = null;
        _tempInjuryOvercome = false;
        _injuryNotesController.clear();
        _painfulExercisesController.clear();
      });

      // Show dialog asking if they want to add another injury
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: CleanTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: CleanTheme.accentGreen,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  AppLocalizations.of(context)!.injuryAddedTitle,
                  style: GoogleFonts.inter(
                    color: CleanTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  AppLocalizations.of(context)!.injuryAddedSubtitle,
                  style: GoogleFonts.inter(
                    color: CleanTheme.textSecondary,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Buttons
                Column(
                  children: [
                    // Primary button - Add another
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Reset temp variables
                          setState(() {
                            _tempInjuryCategory = null;
                            _tempInjuryArea = null;
                            _tempInjuryTiming = InjuryTiming.current;
                            _tempInjurySide = null;
                            _tempInjuryOvercome = false;
                            _painfulExercisesController.clear();
                            _injuryNotesController.clear();
                            _tempInjurySeverity = InjurySeverity.moderate;
                          });

                          // Navigate back to Category selection (2 steps back)
                          _pageController.animateToPage(
                            _currentStep - 2,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CleanTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.addAnotherInjury,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Secondary button - Continue
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate back to "Has Injuries" page to show the list
                          // We need to go back 3 steps: Details -> Area -> Category -> Has Injuries
                          _pageController.animateToPage(
                            _currentStep - 3,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: CleanTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.continueNoInjury,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Apply defaults for non-advanced users
      if (_selectedLevel != ExperienceLevel.advanced) {
        // Default Split based on goal
        if (_selectedGoals.contains(FitnessGoal.muscleGain) ||
            _selectedGoals.contains(FitnessGoal.strength)) {
          _selectedSplit = TrainingSplit.monofrequency;
        } else {
          _selectedSplit = TrainingSplit.multifrequency;
        }

        // Default Workout Type based on goal
        if (_selectedGoals.contains(FitnessGoal.strength)) {
          _selectedWorkoutType = WorkoutType.strength;
        } else if (_selectedGoals.contains(FitnessGoal.muscleGain) ||
            _selectedGoals.contains(FitnessGoal.toning)) {
          _selectedWorkoutType = WorkoutType.hypertrophy;
        } else if (_selectedGoals.contains(FitnessGoal.wellness)) {
          _selectedWorkoutType = WorkoutType.functional;
        } else {
          _selectedWorkoutType = WorkoutType.hypertrophy; // Fallback
        }
      }

      // Map injuries to limitations strings (legacy format)
      final limitations = _injuries
          .map(
            (i) =>
                '${i.category.displayName}: ${i.area.displayName} (${i.severity.displayName})',
          )
          .toList();

      // Convert injuries to detailed format for backend
      final detailedInjuries = _injuries.map((i) => i.toJson()).toList();

      final success = await authProvider.updateProfile(
        goal: _selectedGoals.isNotEmpty
            ? _selectedGoals.first.toString().split('.').last
            : null, // Keep for backward compatibility
        goals: _selectedGoals
            .map((g) => g.toString().split('.').last)
            .toList(), // NEW: Send all selected goals
        level: _selectedLevel?.toString().split('.').last,
        weeklyFrequency: _weeklyFrequency,
        location: _selectedLocation?.toString().split('.').last,
        equipment: _selectedEquipment
            .map((e) => e.toString().split('.').last)
            .toList(),
        limitations: limitations, // Legacy format
        detailedInjuries: detailedInjuries, // NEW: Detailed injuries
        trainingSplit: _selectedSplit.toString().split('.').last,
        sessionDuration: _sessionDuration,
        cardioPreference: _cardioPreference.toString().split('.').last,
        mobilityPreference: _mobilityPreference.toString().split('.').last,
        height: _height,
        weight: _weight,
        gender: _selectedGender?.toString().split('.').last,
        age: _age,
        bodyShape: _selectedBodyShape?.toString().split('.').last,
        workoutType: _selectedWorkoutType?.toString().split('.').last,
        specificMachines: _selectedMachines.toList(),
        bodyweightType: _selectedBodyweightType,
        bodyweightEquipment: _selectedBodyweightEquipment.toList(),
        // Professional Trainer Fields

        // preferredDays removed
        timePreference: _timePreference?.toString().split('.').last,
        sleepHours: _sleepHours,
        recoveryCapacity: _recoveryCapacity?.toString().split('.').last,
        nutritionApproach: _nutritionApproach != null
            ? _camelToSnake(_nutritionApproach.toString().split('.').last)
            : null,
        bodyFatPercentage: _bodyFatPercentage != null
            ? _camelToSnake(_bodyFatPercentage.toString().split('.').last)
            : null,
        trainingHistory: _trainingHistory != null
            ? _camelToSnake(_trainingHistory.toString().split('.').last)
            : null,
        additionalNotes: _prefNotesController.text.trim().isNotEmpty
            ? _prefNotesController.text.trim()
            : null,
        silent: true,
      );

      if (success) {
        if (mounted) {
          // Go directly to the main app - no forced measurements or trial workout
          // Users can access these features optionally from within the app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error ??
                    'Errore durante il salvataggio del profilo',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore imprevisto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total pages dynamically based on current state
    // Base pages: 15 (Gigi, Height, Gender, BodyFat, Goal, Level, Freq, Time, Location, Equipment, Injuries, Duration, Sleep, Nutrition, Cardio, Notes)
    // + Conditional pages based on selections
    int totalPages = 15; // Base count without conditionals

    // Add conditional pages if applicable
    if (_selectedEquipment.contains(Equipment.bodyweight) &&
        !_selectedEquipment.contains(Equipment.machines)) {
      totalPages++; // Bodyweight type
    }
    if (_selectedEquipment.contains(Equipment.machines) &&
        _selectedLocation != TrainingLocation.gym) {
      totalPages++; // Specific machines
    }
    if (_hasInjuries == true) {
      totalPages += 3; // Injury category, area, details
    }
    if (_selectedLevel == ExperienceLevel.advanced) {
      totalPages += 2; // Workout type, training split
    }

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Dot Progress Indicator (one dot per page)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: CleanTheme.textPrimary,
                    ),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _previousPage();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),

                  // Dot Progress Indicator (centered)
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalPages, (index) {
                          final isActive = index == _currentStep;
                          final isCompleted = index < _currentStep;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive || isCompleted
                                  ? CleanTheme.textPrimary
                                  : CleanTheme.borderSecondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Strictly controlled navigation
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  // 0. GIGI WELCOME PAGE (First step)
                  _buildGigiWelcomePage(),

                  // 1. Height & Weight ("Parlaci di te")
                  _buildHeightWeightPage(),

                  // 2. Gender & Age
                  _buildGenderAgePage(),

                  // 3. Body Fat Percentage
                  if (_selectedGender != null) _buildBodyFatPage(),

                  // 4. Goal (Multi-select) - RESTORED
                  _buildMultiSelectionPage(
                    title: AppLocalizations.of(context)!.questionGoal,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.questionGoalSubtitle,
                    options: FitnessGoal.values
                        .where((g) => g != FitnessGoal.toning)
                        .map(
                          (g) => _Option(
                            label: _getGoalLabel(g),
                            icon: _getGoalIcon(g),
                            isSelected: _selectedGoals.contains(g),
                            onTap: () {
                              setState(() {
                                if (_selectedGoals.contains(g)) {
                                  _selectedGoals.remove(g);
                                } else {
                                  if (g == FitnessGoal.weightLoss) {
                                    _selectedGoals.remove(
                                      FitnessGoal.muscleGain,
                                    );
                                  } else if (g == FitnessGoal.muscleGain) {
                                    _selectedGoals.remove(
                                      FitnessGoal.weightLoss,
                                    );
                                  }
                                  _selectedGoals.add(g);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                    canContinue: _selectedGoals.isNotEmpty,
                    onContinue: _nextPage,
                  ),

                  // 5. Experience Level - RESTORED
                  _buildSelectionPage(
                    title: AppLocalizations.of(context)!.questionLevel,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.questionLevelSubtitle,
                    options: ExperienceLevel.values
                        .map(
                          (l) => _Option(
                            label: _getLevelLabel(l),
                            icon: _getLevelIcon(l),
                            isSelected: _selectedLevel == l,
                            onTap: () {
                              setState(() => _selectedLevel = l);
                              _nextPage();
                            },
                          ),
                        )
                        .toList(),
                  ),

                  // 6. Frequency & Preferred Days
                  _buildWeeklyFrequencyPage(),

                  // 2.5 Time Preference (New)
                  _buildTimePreferencePage(),

                  // 3. Location
                  _buildSelectionPage(
                    title: AppLocalizations.of(context)!.questionLocation,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.questionLocationSubtitle,
                    options: TrainingLocation.values
                        .map(
                          (l) => _Option(
                            label: _getLocationLabel(l),
                            icon: _getLocationIcon(l),
                            isSelected: _selectedLocation == l,
                            onTap: () {
                              setState(() => _selectedLocation = l);
                              _nextPage();
                            },
                          ),
                        )
                        .toList(),
                  ),

                  // 4. Equipment
                  _buildEquipmentPage(),

                  // 4.5 Bodyweight Type (Conditional - only if ONLY bodyweight selected, without machines)
                  if (_selectedEquipment.contains(Equipment.bodyweight) &&
                      !_selectedEquipment.contains(Equipment.machines))
                    _buildBodyweightTypePage(),

                  // 4.6 Specific Machines (Conditional - only for non-gym locations)
                  if (_selectedEquipment.contains(Equipment.machines) &&
                      _selectedLocation != TrainingLocation.gym)
                    _buildSpecificMachinesPage(),

                  // 5. Has Injuries? (Gateway to Injury Flow)
                  _buildHasInjuriesPage(),

                  // 6. Injury Category (Conditional)
                  if (_hasInjuries == true) _buildInjuryCategoryPage(),

                  // 7. Injury Area (Conditional)
                  if (_hasInjuries == true) _buildInjuryAreaPage(),

                  // 8. Injury Details (Conditional)
                  if (_hasInjuries == true) _buildInjuryDetailsPage(),

                  // 9. Duration
                  _buildDurationPage(),

                  // 10. Sleep & Recovery (New)
                  _buildSleepRecoveryPage(),

                  // 10.5 Nutrition Approach (New)
                  _buildNutritionApproachPage(),

                  // 11. Cardio & Mobility
                  _buildCardioMobilityPage(),

                  // 12. Workout Type (Only for Advanced)
                  if (_selectedLevel == ExperienceLevel.advanced)
                    _buildWorkoutTypePage(),

                  // 13. Training Split (Only for Advanced)
                  if (_selectedLevel == ExperienceLevel.advanced)
                    _buildTrainingSplitPage(),

                  // 14. Final Notes
                  _buildFinalNotesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Page Builders ---

  /// Welcome page with Gigi - First step of the questionnaire
  Widget _buildGigiWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Gigi Image
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gigi_trainer.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 80,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title with emoji
          // Title with emoji
          Text(
            AppLocalizations.of(context)!.introTitle,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          // Description
          Text(
            AppLocalizations.of(context)!.introDescription,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CleanTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 3),

          // Start Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: CleanTheme.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.introButton,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeightWeightPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.sectionAboutYou,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.sectionAboutYouSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // Height Input
                  Text(
                    AppLocalizations.of(context)!.heightLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _height?.toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.hintHeight,
                      hintStyle: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                      ),
                      filled: true,
                      fillColor: CleanTheme.surfaceColor,
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
                        ),
                      ),
                      suffixText: 'cm',
                      suffixStyle: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      _height = double.tryParse(value);
                    }),
                  ),

                  const SizedBox(height: 32),

                  // Weight Input
                  Text(
                    AppLocalizations.of(context)!.labelWeightParentheses,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _weight?.toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.hintWeight,
                      hintStyle: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                      ),
                      filled: true,
                      fillColor: CleanTheme.surfaceColor,
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
                        ),
                      ),
                      suffixText: 'kg',
                      suffixStyle: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      _weight = double.tryParse(value);
                    }),
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: (_height != null && _weight != null)
                        ? _nextPage
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionPage({
    required String title,
    required String subtitle,
    required List<_Option> options,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  // Replace Expanded/ListView with Column of items since we are inside SingleChildScrollView
                  ...options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CleanCard(
                        isSelected: option.isSelected,
                        onTap: option.onTap,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option.icon,
                                color: CleanTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  if (option.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      option.description!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (option.isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectionPage({
    required String title,
    required String subtitle,
    required List<_Option> options,
    required bool canContinue,
    required VoidCallback onContinue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 8),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  ...options.map((option) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CleanCard(
                        isSelected: option.isSelected,
                        onTap: option.onTap,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option.icon,
                                color: CleanTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  if (option.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      option.description!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (option.isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  const SizedBox(height: 16),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: canContinue ? onContinue : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentPage() {
    // Different equipment options based on location
    final List<(Equipment, String, IconData, String)> equipmentOptions;

    if (_selectedLocation == TrainingLocation.gym) {
      // For gym: only show Machines and Bodyweight
      equipmentOptions = [
        (
          Equipment.machines,
          AppLocalizations.of(context)!.equipmentMachines,
          Icons.fitness_center,
          AppLocalizations.of(context)!.equipmentMachinesDesc,
        ),
        (
          Equipment.bodyweight,
          AppLocalizations.of(context)!.equipmentBodyweight,
          Icons.accessibility_new,
          AppLocalizations.of(context)!.equipmentBodyweightDesc,
        ),
      ];
    } else {
      // For home and outdoor: show all equipment options
      equipmentOptions = [
        (
          Equipment.bench,
          AppLocalizations.of(context)!.equipmentBench,
          Icons.chair_alt,
          AppLocalizations.of(context)!.equipmentBenchDesc,
        ),
        (
          Equipment.dumbbells,
          AppLocalizations.of(context)!.equipmentDumbbells,
          Icons.fitness_center,
          AppLocalizations.of(context)!.equipmentDumbbellsDesc,
        ),
        (
          Equipment.barbell,
          AppLocalizations.of(context)!.equipmentBarbell,
          Icons.horizontal_rule,
          AppLocalizations.of(context)!.equipmentBarbellDesc,
        ),
        (
          Equipment.resistanceBands,
          AppLocalizations.of(context)!.equipmentBands,
          Icons.waves,
          AppLocalizations.of(context)!.equipmentBandsDesc,
        ),
        (
          Equipment.machines,
          AppLocalizations.of(context)!.equipmentMachines,
          Icons.settings,
          AppLocalizations.of(context)!.equipmentMachinesHomeDesc,
        ),
        (
          Equipment.bodyweight,
          AppLocalizations.of(context)!.equipmentBodyweight,
          Icons.accessibility_new,
          AppLocalizations.of(context)!.equipmentBodyweightHomeDesc,
        ),
      ];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.equipmentTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLocation == TrainingLocation.gym
                ? AppLocalizations.of(context)!.equipmentSubtitleGym
                : AppLocalizations.of(context)!.equipmentSubtitleHome,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CleanTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (_selectedLocation == TrainingLocation.gym)
                  ? 2
                  : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: (_selectedLocation == TrainingLocation.gym)
                  ? 0.90
                  : 1.0,
            ),
            itemCount: equipmentOptions.length,
            itemBuilder: (context, index) {
              final item = equipmentOptions[index];
              final isSelected = _selectedEquipment.contains(item.$1);
              return CleanCard(
                isSelected: isSelected,
                padding: const EdgeInsets.all(16),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedEquipment.remove(item.$1);
                    } else {
                      _selectedEquipment.add(item.$1);
                    }
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.surfaceColor,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : CleanTheme.borderSecondary,
                        ),
                      ),
                      child: Icon(
                        item.$3,
                        size: 32,
                        color: isSelected
                            ? CleanTheme.surfaceColor
                            : CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? CleanTheme.textPrimary
                            : CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$4,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CleanButton(
              text: 'Continua',
              onPressed: _selectedEquipment.isNotEmpty ? _nextPage : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificMachinesPage() {
    final machineOptions = [
      'Leg Press',
      'Lat Machine',
      'Chest Press',
      'Leg Extension',
      'Leg Curl',
      'Cable Station',
      'Smith Machine',
      'Shoulder Press',
      'Rowing Machine',
      'Abductor/Adductor',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.machinesTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.machinesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ...machineOptions.map((machine) {
                    final isSelected = _selectedMachines.contains(machine);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CleanCard(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedMachines.remove(machine);
                            } else {
                              _selectedMachines.add(machine);
                            }
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: isSelected
                                  ? CleanTheme.primaryColor
                                  : CleanTheme.textSecondary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              machine,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: isSelected
                                        ? CleanTheme.primaryColor
                                        : CleanTheme.textPrimary,
                                  ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyweightTypePage() {
    final types = [
      (
        'functional',
        AppLocalizations.of(context)!.bodyweightFunctional,
        AppLocalizations.of(context)!.bodyweightFunctionalDesc,
        Icons.bubble_chart,
      ),
      (
        'calisthenics',
        AppLocalizations.of(context)!.bodyweightCalisthenics,
        AppLocalizations.of(context)!.bodyweightCalisthenicsDesc,
        Icons.accessibility_new,
      ),
      (
        'pure',
        AppLocalizations.of(context)!.bodyweightPure,
        AppLocalizations.of(context)!.bodyweightPureDesc,
        Icons.person_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.bodyweightTypeTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.bodyweightTypeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ...types.map((option) {
                    final isSelected = _selectedBodyweightType == option.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CleanCard(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedBodyweightType = option.$1;
                            _selectedBodyweightEquipment.clear();
                          });
                          // If pure bodyweight, skip sub-selection
                          if (option.$1 == 'pure') {
                            _nextPage();
                          } else {
                            // Show equipment sub-selection dialog
                            _showBodyweightEquipmentDialog(option.$1);
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option.$4,
                                color: CleanTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.$2,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.$3,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBodyweightEquipmentDialog(String type) {
    List<(String, String, IconData)> options;

    if (type == 'functional') {
      options = [
        (
          'trx',
          AppLocalizations.of(context)!.equipmentTrx,
          Icons.fitness_center,
        ),
        ('bands', AppLocalizations.of(context)!.equipmentBandsAlt, Icons.waves),
        (
          'fitball',
          AppLocalizations.of(context)!.equipmentFitball,
          Icons.sports_baseball,
        ),
        (
          'bosu',
          AppLocalizations.of(context)!.equipmentBosu,
          Icons.panorama_wide_angle,
        ),
      ];
    } else {
      // calisthenics
      options = [
        (
          'bar',
          AppLocalizations.of(context)!.equipmentPullUpBar,
          Icons.horizontal_rule,
        ),
        (
          'rings',
          AppLocalizations.of(context)!.equipmentRings,
          Icons.radio_button_off,
        ),
        (
          'parallels',
          AppLocalizations.of(context)!.equipmentParallels,
          Icons.view_column,
        ),
        (
          'wall',
          AppLocalizations.of(context)!.equipmentWallBars,
          Icons.grid_on,
        ),
      ];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'functional'
                    ? AppLocalizations.of(context)!.bwEquipmentFunctionalTitle
                    : AppLocalizations.of(
                        context,
                      )!.bwEquipmentCalisthenicsTitle,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.bwEquipmentSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: options.map((opt) {
                  final isSelected = _selectedBodyweightEquipment.contains(
                    opt.$1,
                  );
                  return FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(opt.$3, size: 18),
                        const SizedBox(width: 8),
                        Text(opt.$2),
                      ],
                    ),
                    onSelected: (selected) {
                      setSheetState(() {
                        if (selected) {
                          _selectedBodyweightEquipment.add(opt.$1);
                        } else {
                          _selectedBodyweightEquipment.remove(opt.$1);
                        }
                      });
                      setState(() {});
                    },
                    selectedColor: CleanTheme.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                    checkmarkColor: CleanTheme.primaryColor,
                  );
                }).toList(),
              ),
              const Spacer(),
              const SizedBox(height: 16),
              CleanButton(
                text: AppLocalizations.of(context)!.continueButton,
                onPressed: _selectedBodyweightEquipment.isNotEmpty
                    ? () {
                        Navigator.pop(context);
                        _nextPage();
                      }
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CleanButton(
                  text: AppLocalizations.of(context)!.continueButton,
                  onPressed: () {
                    Navigator.pop(context);
                    _nextPage();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHasInjuriesPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.injuriesTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _injuries.isEmpty
                        ? AppLocalizations.of(context)!.injuriesSubtitleEmpty
                        : AppLocalizations.of(
                            context,
                          )!.injuriesSubtitleFilled(_injuries.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // List existing injuries if any
                  if (_injuries.isNotEmpty) ...[
                    ..._injuries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final injury = entry.value;
                      return CleanCard(
                        backgroundColor: CleanTheme.surfaceColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(
                            injury.category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            injury.area.displayName,
                            style: GoogleFonts.inter(
                              color: CleanTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            injury.severity.displayName,
                            style: GoogleFonts.inter(
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                setState(() => _injuries.removeAt(index)),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],

                  CleanCard(
                    onTap: () {
                      setState(() => _hasInjuries = true);
                      _nextPage(); // Go to Category selection
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: CleanTheme.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _injuries.isEmpty
                              ? AppLocalizations.of(context)!.yesInjury
                              : AppLocalizations.of(context)!.addAnotherInjury,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CleanCard(
                    onTap: () {
                      setState(() => _hasInjuries = false);
                      // Skip injury steps.
                      _nextPage();
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.greenAccent,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _injuries.isEmpty
                              ? AppLocalizations.of(context)!.noInjury
                              : AppLocalizations.of(context)!.noMoreInjuries,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInjuryCategoryPage() {
    return _buildSelectionPage(
      title: AppLocalizations.of(context)!.injuryCategoryTitle,
      subtitle: AppLocalizations.of(context)!.injuryCategorySubtitle,
      options: InjuryCategory.values
          .map(
            (c) => _Option(
              label: c.displayName,
              icon: Icons
                  .healing, // Placeholder, ideally map c.icon (string) to widget
              description: 'Es. ${_getInjuryExample(c)}',
              isSelected: _tempInjuryCategory == c,
              onTap: () {
                setState(() => _tempInjuryCategory = c);
                _nextPage();
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildInjuryAreaPage() {
    final List<InjuryArea> areas = _tempInjuryCategory != null
        ? InjuryArea.values
              .where((a) => a.category == _tempInjuryCategory)
              .toList()
        : <InjuryArea>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.injuryAreaTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 24),
                  // Use a Wrap or Column with Rows instead of Expanded GridView
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: areas.map((area) {
                      return SizedBox(
                        width: (constraints.maxWidth - 48 - 12) / 2,
                        child: CleanCard(
                          isSelected: _tempInjuryArea == area,
                          onTap: () {
                            setState(() => _tempInjuryArea = area);
                            _nextPage();
                          },
                          child: Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: Text(
                              area.displayName,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInjuryDetailsPage() {
    // Determine if side selection is applicable based on injury area
    final bool isSideApplicable =
        _tempInjuryArea != null &&
        ![
          InjuryArea.neck,
          InjuryArea.abs,
          InjuryArea.obliques,
          InjuryArea.lowerBack,
          InjuryArea.upperBack,
          InjuryArea.cervicalSpine,
          InjuryArea.thoracicSpine,
          InjuryArea.lumbarSpine,
          InjuryArea.sacroiliac,
        ].contains(_tempInjuryArea);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timing Selection
          Text(
            AppLocalizations.of(context)!.injuryTimingTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          ...InjuryTiming.values.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CleanCard(
                isSelected: _tempInjuryTiming == t,
                onTap: () => setState(() {
                  _tempInjuryTiming = t;
                  // Reset overcome status when switching timing
                  if (t == InjuryTiming.current) {
                    _tempInjuryOvercome = false;
                  }
                }),
                child: Row(
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(
                      t.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Side Selection (conditional)
          if (isSideApplicable) ...[
            Text(
              AppLocalizations.of(context)!.injurySideTitle,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            ...[
              ('left', AppLocalizations.of(context)!.sideLeft, '⬅️'),
              ('right', AppLocalizations.of(context)!.sideRight, '➡️'),
              ('bilateral', AppLocalizations.of(context)!.sideBilateral, '↔️'),
            ].map(
              (side) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CleanCard(
                  isSelected: _tempInjurySide == side.$1,
                  onTap: () => setState(() => _tempInjurySide = side.$1),
                  child: Row(
                    children: [
                      Text(side.$3, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Text(
                        side.$2,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Overcome status (only for past injuries) - TWO SEPARATE BUTTONS
          if (_tempInjuryTiming == InjuryTiming.past) ...[
            Text(
              AppLocalizations.of(context)!.injuryStatusTitle,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.injuryStatusSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Button: Superato
            CleanCard(
              isSelected: _tempInjuryOvercome == true,
              onTap: () => setState(() => _tempInjuryOvercome = true),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: _tempInjuryOvercome == true
                        ? Colors.green
                        : CleanTheme.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✅ ${AppLocalizations.of(context)!.injuryStatusOvercome}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _tempInjuryOvercome == true
                                    ? Colors.green
                                    : CleanTheme.textPrimary,
                              ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.injuryStatusOvercomeDesc,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Button: Ancora Presente
            CleanCard(
              isSelected: _tempInjuryOvercome == false,
              onTap: () => setState(() => _tempInjuryOvercome = false),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: _tempInjuryOvercome == false
                        ? Colors.orange
                        : CleanTheme.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ ${AppLocalizations.of(context)!.injuryStatusActive}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _tempInjuryOvercome == false
                                    ? Colors.orange
                                    : CleanTheme.textPrimary,
                              ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.injuryStatusActiveDesc,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Severity
          Text(
            AppLocalizations.of(context)!.injurySeverityTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          ...InjurySeverity.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CleanCard(
                isSelected: _tempInjurySeverity == s,
                onTap: () => setState(() => _tempInjurySeverity = s),
                child: Row(
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(
                      s.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Painful Exercises
          Text(
            AppLocalizations.of(context)!.painfulExercisesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _painfulExercisesController,
            maxLines: 2,
            style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.painfulExercisesHint,
              fillColor: CleanTheme.surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Notes
          Text(
            AppLocalizations.of(context)!.notesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _injuryNotesController,
            maxLines: 3,
            style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.notesHint,
              fillColor: CleanTheme.surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),
          CleanButton(
            text: AppLocalizations.of(context)!.saveInjuryButton,
            onPressed: _addInjury,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.sessionDurationTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.sessionDurationSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$_sessionDuration min',
                          style: GoogleFonts.outfit(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: CleanTheme.primaryColor,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: CleanTheme.primaryColor.withAlpha(
                              (0.2 * 255).round(),
                            ),
                          ),
                          child: Slider(
                            value: _sessionDuration.toDouble(),
                            min: 30,
                            max: 120,
                            divisions: 9,
                            onChanged: (value) => setState(
                              () => _sessionDuration = value.toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 32),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardioMobilityPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.cardioMobilityTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.cardioSection,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  ...CardioPreference.values
                      .where((p) => p != CardioPreference.separateSession)
                      .map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CleanCard(
                            isSelected: _cardioPreference == p,
                            onTap: () => setState(() => _cardioPreference = p),
                            child: Row(
                              children: [
                                Text(
                                  p.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getCardioLabel(p),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      Text(
                                        _getCardioDescription(p),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.mobilitySection,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  ...MobilityPreference.values
                      .where((p) => p != MobilityPreference.dedicatedSession)
                      .map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CleanCard(
                            isSelected: _mobilityPreference == p,
                            onTap: () =>
                                setState(() => _mobilityPreference = p),
                            child: Row(
                              children: [
                                Text(
                                  p.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getMobilityLabel(p),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      Text(
                                        _getMobilityDescription(p),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  const Spacer(),
                  const SizedBox(height: 24),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainingSplitPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.trainingSplitTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.trainingSplitSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  ...TrainingSplit.values.map((split) {
                    final isSelected = _selectedSplit == split;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CleanCard(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedSplit = split);
                          _nextPage();
                        },
                        child: Row(
                          children: [
                            Text(
                              split.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getSplitLabel(split),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSplitDescription(split),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalNotesPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.finalDetailsTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.finalDetailsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.finalDetailsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CleanTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.finalDetailsBulletTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: CleanTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.bulletPreferences,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.bulletGoals,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.bulletMedical,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _prefNotesController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(color: CleanTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.finalNotesHint,
                      fillColor: CleanTheme.primaryLight,
                      filled: true,
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
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),
                  CleanButton(
                    text: _isLoading
                        ? AppLocalizations.of(context)!.savingButton
                        : AppLocalizations.of(context)!.proceedButton,
                    onPressed: _isLoading ? null : _finish,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: CleanTheme.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: CleanTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _camelToSnake(String camelCase) {
    return camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  // --- Helpers ---

  String _getGoalLabel(FitnessGoal g) {
    switch (g) {
      case FitnessGoal.muscleGain:
        return AppLocalizations.of(context)!.goalMuscleGainLabel;
      case FitnessGoal.weightLoss:
        return AppLocalizations.of(context)!.goalWeightLossLabel;
      case FitnessGoal.toning:
        return AppLocalizations.of(context)!.goalToningLabel;
      case FitnessGoal.strength:
        return AppLocalizations.of(context)!.goalStrengthLabel;
      case FitnessGoal.wellness:
        return AppLocalizations.of(context)!.goalWellnessLabel;
    }
  }

  IconData _getGoalIcon(FitnessGoal g) {
    switch (g) {
      case FitnessGoal.muscleGain:
        return Icons.fitness_center;
      case FitnessGoal.weightLoss:
        return Icons.local_fire_department;
      case FitnessGoal.toning:
        return Icons.accessibility_new;
      case FitnessGoal.strength:
        return Icons.bolt;
      case FitnessGoal.wellness:
        return Icons.favorite;
    }
  }

  String _getLevelLabel(ExperienceLevel l) {
    switch (l) {
      case ExperienceLevel.beginner:
        return AppLocalizations.of(context)!.levelBeginnerLabel;
      case ExperienceLevel.intermediate:
        return AppLocalizations.of(context)!.levelIntermediateLabel;
      case ExperienceLevel.advanced:
        return AppLocalizations.of(context)!.levelAdvancedLabel;
    }
  }

  IconData _getLevelIcon(ExperienceLevel l) {
    switch (l) {
      case ExperienceLevel.beginner:
        return Icons.star_border;
      case ExperienceLevel.intermediate:
        return Icons.star_half;
      case ExperienceLevel.advanced:
        return Icons.star;
    }
  }

  String _getLocationLabel(TrainingLocation l) {
    switch (l) {
      case TrainingLocation.gym:
        return AppLocalizations.of(context)!.locationGymLabel;
      case TrainingLocation.home:
        return AppLocalizations.of(context)!.locationHomeLabel;
      case TrainingLocation.outdoor:
        return AppLocalizations.of(context)!.locationOutdoorLabel;
    }
  }

  IconData _getLocationIcon(TrainingLocation l) {
    switch (l) {
      case TrainingLocation.gym:
        return Icons.fitness_center;
      case TrainingLocation.home:
        return Icons.home;
      case TrainingLocation.outdoor:
        return Icons.park;
    }
  }

  String _getInjuryExample(InjuryCategory c) {
    switch (c) {
      case InjuryCategory.muscular:
        return AppLocalizations.of(context)!.injuryMuscular;
      case InjuryCategory.articular:
        return AppLocalizations.of(context)!.injuryArticular;
      case InjuryCategory.bone:
        return AppLocalizations.of(context)!.injuryBone;
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return AppLocalizations.of(context)!.workoutStrength;
      case WorkoutType.hypertrophy:
        return AppLocalizations.of(context)!.workoutHypertrophy;
      case WorkoutType.endurance:
        return AppLocalizations.of(context)!.workoutEndurance;
      case WorkoutType.functional:
        return AppLocalizations.of(context)!.workoutFunctional;
      case WorkoutType.calisthenics:
        return AppLocalizations.of(context)!.workoutCalisthenics;
    }
  }

  String _getWorkoutTypeDescription(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return AppLocalizations.of(context)!.workoutStrengthDesc;
      case WorkoutType.hypertrophy:
        return AppLocalizations.of(context)!.workoutHypertrophyDesc;
      case WorkoutType.endurance:
        return AppLocalizations.of(context)!.workoutEnduranceDesc;
      case WorkoutType.functional:
        return AppLocalizations.of(context)!.workoutFunctionalDesc;
      case WorkoutType.calisthenics:
        return AppLocalizations.of(context)!.workoutCalisthenicsDesc;
    }
  }

  IconData _getWorkoutTypeIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return Icons.bolt;
      case WorkoutType.hypertrophy:
        return Icons.fitness_center;
      case WorkoutType.endurance:
        return Icons.timer;
      case WorkoutType.functional:
        return Icons.directions_run;
      case WorkoutType.calisthenics:
        return Icons.accessibility_new;
    }
  }

  String _getSplitLabel(TrainingSplit s) {
    switch (s) {
      case TrainingSplit.monofrequency:
        return AppLocalizations.of(context)!.splitMonofrequency;
      case TrainingSplit.multifrequency:
        return AppLocalizations.of(context)!.splitMultifrequency;
      case TrainingSplit.upperLower:
        return AppLocalizations.of(context)!.splitUpperLower;
      case TrainingSplit.pushPullLegs:
        return AppLocalizations.of(context)!.splitPushPullLegs;
      case TrainingSplit.fullBody:
        return AppLocalizations.of(context)!.splitFullBody;
      case TrainingSplit.bodyPartSplit:
        return AppLocalizations.of(context)!.splitBodyPart;
      case TrainingSplit.arnoldSplit:
        return AppLocalizations.of(context)!.splitArnold;
    }
  }

  String _getSplitDescription(TrainingSplit s) {
    switch (s) {
      case TrainingSplit.monofrequency:
        return AppLocalizations.of(context)!.splitMonofrequencyDesc;
      case TrainingSplit.multifrequency:
        return AppLocalizations.of(context)!.splitMultifrequencyDesc;
      case TrainingSplit.upperLower:
        return AppLocalizations.of(context)!.splitUpperLowerDesc;
      case TrainingSplit.pushPullLegs:
        return AppLocalizations.of(context)!.splitPushPullLegsDesc;
      case TrainingSplit.fullBody:
        return AppLocalizations.of(context)!.splitFullBodyDesc;
      case TrainingSplit.bodyPartSplit:
        return AppLocalizations.of(context)!.splitBodyPartDesc;
      case TrainingSplit.arnoldSplit:
        return AppLocalizations.of(context)!.splitArnoldDesc;
    }
  }

  String _getCardioLabel(CardioPreference c) {
    switch (c) {
      case CardioPreference.none:
        return AppLocalizations.of(context)!.cardioNone;
      case CardioPreference.warmUp:
        return AppLocalizations.of(context)!.cardioWarmUp;
      case CardioPreference.postWorkout:
        return AppLocalizations.of(context)!.cardioPostWorkout;
      case CardioPreference.separateSession:
        return AppLocalizations.of(context)!.cardioSeparate;
    }
  }

  String _getCardioDescription(CardioPreference c) {
    switch (c) {
      case CardioPreference.none:
        return AppLocalizations.of(context)!.cardioNoneDesc;
      case CardioPreference.warmUp:
        return AppLocalizations.of(context)!.cardioWarmUpDesc;
      case CardioPreference.postWorkout:
        return AppLocalizations.of(context)!.cardioPostWorkoutDesc;
      case CardioPreference.separateSession:
        return AppLocalizations.of(context)!.cardioSeparateDesc;
    }
  }

  String _getMobilityLabel(MobilityPreference m) {
    switch (m) {
      case MobilityPreference.none:
        return AppLocalizations.of(context)!.mobilityNone;
      case MobilityPreference.postWorkout:
        return AppLocalizations.of(context)!.mobilityPostWorkout;
      case MobilityPreference.preWorkout:
        return AppLocalizations.of(context)!.mobilityPreWorkout;
      case MobilityPreference.dedicatedSession:
        return AppLocalizations.of(context)!.mobilityDedicated;
    }
  }

  String _getMobilityDescription(MobilityPreference m) {
    switch (m) {
      case MobilityPreference.none:
        return AppLocalizations.of(context)!.mobilityNoneDesc;
      case MobilityPreference.postWorkout:
        return AppLocalizations.of(context)!.mobilityPostWorkoutDesc;
      case MobilityPreference.preWorkout:
        return AppLocalizations.of(context)!.mobilityPreWorkoutDesc;
      case MobilityPreference.dedicatedSession:
        return AppLocalizations.of(context)!.mobilityDedicatedDesc;
    }
  }

  Widget _buildWeeklyFrequencyPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.questionFrequencyTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.questionFrequencySubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // Frequency Slider
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '$_weeklyFrequency ${AppLocalizations.of(context)!.days}',
                          style: GoogleFonts.outfit(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: CleanTheme.primaryColor,
                            inactiveTrackColor: CleanTheme.borderPrimary,
                            thumbColor: CleanTheme.primaryColor,
                            overlayColor: CleanTheme.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          child: Slider(
                            value: _weeklyFrequency.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            onChanged: (value) => setState(
                              () => _weeklyFrequency = value.toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 32),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutTypePage() {
    return _buildSelectionPage(
      title: AppLocalizations.of(context)!.questionWorkoutTypeTitle,
      subtitle: AppLocalizations.of(context)!.questionWorkoutTypeSubtitle,
      options: WorkoutType.values
          .map(
            (t) => _Option(
              label: _getWorkoutTypeLabel(t),
              icon: _getWorkoutTypeIcon(t),
              description: _getWorkoutTypeDescription(t),
              isSelected: _selectedWorkoutType == t,
              onTap: () {
                setState(() => _selectedWorkoutType = t);
                _nextPage();
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildGenderAgePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48, // Account for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.questionGenderTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.questionGenderSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Gender Selection
                  Text(
                    AppLocalizations.of(context)!.labelGenderTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Male option
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGender = Gender.male),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: _selectedGender == Gender.male
                                  ? CleanTheme.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedGender == Gender.male
                                    ? CleanTheme.textPrimary
                                    : CleanTheme.borderSecondary,
                                width: _selectedGender == Gender.male ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.male,
                                  color: _selectedGender == Gender.male
                                      ? CleanTheme.textPrimary
                                      : CleanTheme.textTertiary,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.genderMale,
                                  style: TextStyle(
                                    color: _selectedGender == Gender.male
                                        ? CleanTheme.textPrimary
                                        : CleanTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Female option
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGender = Gender.female),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: _selectedGender == Gender.female
                                  ? CleanTheme.surfaceColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedGender == Gender.female
                                    ? CleanTheme.textPrimary
                                    : CleanTheme.borderSecondary,
                                width: _selectedGender == Gender.female ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.female,
                                  color: _selectedGender == Gender.female
                                      ? CleanTheme.textPrimary
                                      : CleanTheme.textTertiary,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.genderFemale,
                                  style: TextStyle(
                                    color: _selectedGender == Gender.female
                                        ? CleanTheme.textPrimary
                                        : CleanTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Age Input
                  Text(
                    AppLocalizations.of(context)!.ageLabel,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _age?.toString(),
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.ageHint, // 'Es. 25'
                      hintStyle: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                      ),
                      filled: true,
                      fillColor: CleanTheme.surfaceColor,
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
                        ),
                      ),
                      suffixText: AppLocalizations.of(context)!.years,
                      suffixStyle: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      final parsedAge = int.tryParse(value);
                      // Validate age between 14 and 100
                      if (parsedAge != null &&
                          parsedAge >= 14 &&
                          parsedAge <= 100) {
                        _age = parsedAge;
                      } else {
                        _age = null;
                      }
                    }),
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed:
                        (_selectedGender != null &&
                            _age != null &&
                            _age! >= 14 &&
                            _age! <= 100)
                        ? _nextPage
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Professional Trainer Page Builders ---

  Widget _buildBodyFatPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.questionBodyFatTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.questionBodyFatSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ...BodyFatPercentage.values.map((bf) {
                    String title;
                    String subtitle;
                    String percentage;
                    IconData icon;

                    switch (bf) {
                      case BodyFatPercentage.veryHigh:
                        title = AppLocalizations.of(context)!.bodyFatVeryHigh;
                        subtitle = AppLocalizations.of(
                          context,
                        )!.bodyFatVeryHighSub;
                        percentage =
                            'Molto Alta (>25%)'; // Keep numerical part literal or tokenize?
                        icon = Icons.accessibility_new;
                        break;
                      case BodyFatPercentage.high:
                        title = AppLocalizations.of(context)!.bodyFatHigh;
                        subtitle = AppLocalizations.of(context)!.bodyFatHighSub;
                        percentage = 'Alta (20-25%)';
                        icon = Icons.accessibility;
                        break;
                      case BodyFatPercentage.average:
                        title = AppLocalizations.of(context)!.bodyFatAverage;
                        subtitle = AppLocalizations.of(
                          context,
                        )!.bodyFatAverageSub;
                        percentage = 'Media (15-20%)';
                        icon = Icons.person;
                        break;
                      case BodyFatPercentage.athletic:
                        title = AppLocalizations.of(context)!.bodyFatAthletic;
                        subtitle = AppLocalizations.of(
                          context,
                        )!.bodyFatAthleticSub;
                        percentage = 'Atletica (10-15%)';
                        icon = Icons.fitness_center;
                        break;
                      case BodyFatPercentage.veryLean:
                        title = AppLocalizations.of(context)!.bodyFatVeryLean;
                        subtitle = AppLocalizations.of(
                          context,
                        )!.bodyFatVeryLeanSub;
                        percentage = 'Molto Definita (<10%)';
                        icon = Icons.flash_on;
                        break;
                    }

                    final isSelected = _bodyFatPercentage == bf;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CleanCard(
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _bodyFatPercentage = bf);
                          _nextPage();
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: CleanTheme.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20, // Large
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: CleanTheme.textSecondary,
                                          fontSize: 16, // Medium
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    percentage,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: CleanTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12, // Small
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePreferencePage() {
    return _buildSelectionPage(
      title: AppLocalizations.of(context)!.questionTimeTitle,
      subtitle: AppLocalizations.of(context)!.questionTimeSubtitle,
      options: TimePreference.values.map((t) {
        String label;
        String description;
        IconData icon;

        switch (t) {
          case TimePreference.morning:
            label = AppLocalizations.of(context)!.timeMorning;
            description = AppLocalizations.of(context)!.timeMorningDesc;
            icon = Icons.wb_sunny;
            break;
          case TimePreference.afternoon:
            label = AppLocalizations.of(context)!.timeAfternoon;
            description = AppLocalizations.of(context)!.timeAfternoonDesc;
            icon = Icons.access_time;
            break;
          case TimePreference.evening:
            label = AppLocalizations.of(context)!.timeEvening;
            description = AppLocalizations.of(context)!.timeEveningDesc;
            icon = Icons.nights_stay;
            break;
        }

        return _Option(
          label: label,
          description: description,
          icon: icon,
          isSelected: _timePreference == t,
          onTap: () {
            setState(() => _timePreference = t);
            _nextPage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildSleepRecoveryPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.questionSleepTitle,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.questionSleepSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Sleep Slider
                  Text(
                    '${AppLocalizations.of(context)!.sleepHoursLabel} $_sleepHours',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Slider(
                    value: _sleepHours.toDouble(),
                    min: 4,
                    max: 10,
                    divisions: 6,
                    label: _sleepHours.toString(),
                    activeColor: CleanTheme.primaryColor,
                    onChanged: (val) =>
                        setState(() => _sleepHours = val.round()),
                  ),

                  const SizedBox(height: 32),

                  // Recovery Capacity
                  Text(
                    AppLocalizations.of(context)!.questionRecoveryTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  ...RecoveryCapacity.values.map((r) {
                    String label;
                    String description;

                    switch (r) {
                      case RecoveryCapacity.excellent:
                        label = AppLocalizations.of(context)!.recoveryExcellent;
                        description = AppLocalizations.of(
                          context,
                        )!.recoveryExcellentDesc;
                        break;
                      case RecoveryCapacity.good:
                        label = AppLocalizations.of(context)!.recoveryGood;
                        description = AppLocalizations.of(
                          context,
                        )!.recoveryGoodDesc;
                        break;
                      case RecoveryCapacity.poor:
                        label = AppLocalizations.of(context)!.recoveryPoor;
                        description = AppLocalizations.of(
                          context,
                        )!.recoveryPoorDesc;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: CleanCard(
                        isSelected: _recoveryCapacity == r,
                        onTap: () {
                          setState(() => _recoveryCapacity = r);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              Text(
                                description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const Spacer(),
                  const SizedBox(height: 16),
                  CleanButton(
                    text: AppLocalizations.of(context)!.continueButton,
                    onPressed: (_recoveryCapacity != null) ? _nextPage : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionApproachPage() {
    return _buildSelectionPage(
      title: AppLocalizations.of(context)!.questionNutritionTitle,
      subtitle: AppLocalizations.of(context)!.questionNutritionSubtitle,
      options: NutritionApproach.values.map((n) {
        String label;
        String description;
        IconData icon;

        switch (n) {
          case NutritionApproach.fullTracking:
            label = AppLocalizations.of(context)!.nutritionFullTracking;
            description = AppLocalizations.of(
              context,
            )!.nutritionFullTrackingDesc;
            icon = Icons.calculate;
            break;
          case NutritionApproach.partialTracking:
            label = AppLocalizations.of(context)!.nutritionPartialTracking;
            description = AppLocalizations.of(
              context,
            )!.nutritionPartialTrackingDesc;
            icon = Icons.pie_chart;
            break;
          case NutritionApproach.intuitive:
            label = AppLocalizations.of(context)!.nutritionIntuitive;
            description = AppLocalizations.of(context)!.nutritionIntuitiveDesc;
            icon = Icons.restaurant;
            break;
          case NutritionApproach.none:
            label = AppLocalizations.of(context)!.nutritionNone;
            description = AppLocalizations.of(context)!.nutritionNoneDesc;
            icon = Icons.fastfood;
            break;
        }

        return _Option(
          label: label,
          description: description,
          icon: icon,
          isSelected: _nutritionApproach == n,
          onTap: () {
            setState(() => _nutritionApproach = n);
            _nextPage();
          },
        );
      }).toList(),
    );
  }
}

class _Option {
  final String label;
  final IconData icon;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;

  _Option({
    required this.label,
    required this.icon,
    this.description,
    required this.isSelected,
    required this.onTap,
  });
}
