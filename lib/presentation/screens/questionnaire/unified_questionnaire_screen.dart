import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/injury_model.dart';
import '../../../data/models/training_preferences_model.dart';

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
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _updateProgress();
  }

  void _previousPage() {
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
        builder: (context) => AlertDialog(
          backgroundColor: CleanTheme.cardColor,
          title: const Text(
            'Infortunio Aggiunto',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Hai altri infortuni da segnalare?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
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
              child: const Text('No, Continua'),
            ),
            ElevatedButton(
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
                // We use animateToPage with calculated index to ensure we land on the correct page
                // Current step is Details (Index X). Area is X-1. Category is X-2.
                _pageController.animateToPage(
                  _currentStep - 2,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Sì, Aggiungi Altro'),
            ),
          ],
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
        silent: true,
      );

      if (success) {
        if (mounted) {
          // Navigate to MainScreen (Dashboard) instead of TrialWorkoutChoiceScreen
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/main', (route) => false);
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
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Progress
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (_currentStep > 0) {
                        _previousPage();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            CleanTheme.primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder for symmetry or skip
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
                  // 0. Height & Weight
                  _buildHeightWeightPage(),

                  // 1. Gender & Age
                  _buildGenderAgePage(),

                  // 1.5 Body Fat Percentage (Replaces Body Shape)
                  if (_selectedGender != null) _buildBodyFatPage(),

                  // 3. Goal (Multi-select)
                  _buildMultiSelectionPage(
                    title: 'Qual è il tuo obiettivo?',
                    subtitle:
                        '✨ Puoi selezionarne più di uno per un piano personalizzato.',
                    options: FitnessGoal.values
                        .where(
                          (g) => g != FitnessGoal.toning,
                        ) // Remove Definition
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
                                  // Mutual exclusivity logic
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

                  // 1. Experience
                  _buildSelectionPage(
                    title: 'Il tuo livello?',
                    subtitle: 'Sii onesto, adatteremo tutto a te.',
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

                  // 2. Frequency & Preferred Days
                  _buildWeeklyFrequencyPage(),

                  // 2.5 Time Preference (New)
                  _buildTimePreferencePage(),

                  // 3. Location
                  _buildSelectionPage(
                    title: 'Dove ti allenerai?',
                    subtitle: 'Casa o Palestra?',
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

                  // 4.5 Specific Machines (Conditional - only for non-gym locations)
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

  Widget _buildHeightWeightPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parlaci di te',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Queste informazioni ci aiutano a calcolare il tuo fabbisogno.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 48),

          // Height Input
          Text(
            'Altezza (cm)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _height?.toString(),
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Es. 175',
              hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
              filled: true,
              fillColor: CleanTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.primaryColor),
              ),
              suffixText: 'cm',
              suffixStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
            onChanged: (value) => setState(() {
              _height = double.tryParse(value);
            }),
          ),

          const SizedBox(height: 32),

          // Weight Input
          Text('Peso (kg)', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _weight?.toString(),
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Es. 70',
              hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
              filled: true,
              fillColor: CleanTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.primaryColor),
              ),
              suffixText: 'kg',
              suffixStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
            onChanged: (value) => setState(() {
              _weight = double.tryParse(value);
            }),
          ),

          const Spacer(),
          CleanButton(
            text: 'Continua',
            onPressed: (_height != null && _weight != null) ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPage({
    required String title,
    required String subtitle,
    required List<_Option> options,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = options[index];
                return CleanCard(
                  isSelected: option.isSelected,
                  onTap: option.onTap,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (option.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                option.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectionPage({
    required String title,
    required String subtitle,
    required List<_Option> options,
    required bool canContinue,
    required VoidCallback onContinue,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = options[index];
                return CleanCard(
                  isSelected: option.isSelected,
                  onTap: option.onTap,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (option.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                option.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
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
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          CleanButton(
            text: 'Continua',
            onPressed: canContinue ? onContinue : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentPage() {
    // Different equipment options based on location
    final List<(Equipment, String, IconData)> equipmentOptions;

    if (_selectedLocation == TrainingLocation.gym) {
      // For gym: only show Machines and Bodyweight
      equipmentOptions = [
        (Equipment.machines, 'Macchine', Icons.settings),
        (Equipment.bodyweight, 'Corpo Libero', Icons.accessibility),
      ];
    } else {
      // For home and outdoor: show all equipment options
      equipmentOptions = [
        (Equipment.bench, 'Panca', Icons.chair_alt),
        (Equipment.dumbbells, 'Manubri', Icons.fitness_center),
        (Equipment.barbell, 'Bilanciere', Icons.horizontal_rule),
        (Equipment.resistanceBands, 'Elastici', Icons.waves),
        (Equipment.machines, 'Macchine', Icons.settings),
        (Equipment.bodyweight, 'Corpo Libero', Icons.accessibility),
      ];
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attrezzatura',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedLocation == TrainingLocation.gym
                ? 'Puoi selezionare sia Macchine che Corpo Libero.'
                : 'Cosa hai a disposizione?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: equipmentOptions.length,
              itemBuilder: (context, index) {
                final item = equipmentOptions[index];
                final isSelected = _selectedEquipment.contains(item.$1);
                return CleanCard(
                  isSelected: isSelected,
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
                      Icon(
                        item.$3,
                        size: 32,
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isSelected
                                  ? CleanTheme.primaryColor
                                  : CleanTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          CleanButton(
            text: 'Continua',
            onPressed: _selectedEquipment.isNotEmpty ? _nextPage : null,
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quali Macchine?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona quelle disponibili.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: machineOptions.length,
              itemBuilder: (context, index) {
                final machine = machineOptions[index];
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
              },
            ),
          ),
          const SizedBox(height: 16),
          CleanButton(text: 'Continua', onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildHasInjuriesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Infortuni', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            _injuries.isEmpty
                ? 'Hai infortuni recenti o passati? Inserisci anche quelli passati se rilevanti.'
                : 'Hai aggiunto ${_injuries.length} infortuni. Ne hai altri?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 48),

          // List existing injuries if any
          if (_injuries.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: _injuries.length,
                itemBuilder: (context, index) {
                  final injury = _injuries[index];
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
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () =>
                            setState(() => _injuries.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ),
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
                      ? 'Sì, ho un infortunio'
                      : 'Aggiungi un altro',
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
              // Since we are in a PageView, we need to jump over the injury pages (6, 7, 8)
              // Current index is 6. Target is 7 (Duration) when no injuries.
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
                  _injuries.isEmpty ? 'No, sono sano' : 'No, ho finito',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          if (_injuries.isNotEmpty)
            const Spacer(), // Push buttons up if list is long
        ],
      ),
    );
  }

  Widget _buildInjuryCategoryPage() {
    return _buildSelectionPage(
      title: 'Tipo di infortunio',
      subtitle: 'Seleziona la categoria',
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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zona specifica',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final area = areas[index];
                return CleanCard(
                  isSelected: _tempInjuryArea == area,
                  onTap: () {
                    setState(() => _tempInjuryArea = area);
                    _nextPage();
                  },
                  child: Center(
                    child: Text(
                      area.displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
          Text('Quando?', style: Theme.of(context).textTheme.displayMedium),
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
            Text('Lato', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            ...[
              ('left', 'Sinistro', '⬅️'),
              ('right', 'Destro', '➡️'),
              ('bilateral', 'Bilaterale', '↔️'),
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

          // Overcome status (only for past injuries)
          if (_tempInjuryTiming == InjuryTiming.past) ...[
            Text(
              'È stato superato?',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            CleanCard(
              isSelected: _tempInjuryOvercome,
              onTap: () =>
                  setState(() => _tempInjuryOvercome = !_tempInjuryOvercome),
              child: Row(
                children: [
                  Icon(
                    _tempInjuryOvercome ? Icons.check_circle : Icons.cancel,
                    color: _tempInjuryOvercome ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _tempInjuryOvercome
                        ? 'Sì, superato'
                        : 'No, ancora presente',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Severity
          Text('Gravità', style: Theme.of(context).textTheme.displayMedium),
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
            'Esercizi che causano dolore',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _painfulExercisesController,
            maxLines: 2,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Es: Squat, Panca piana, Stacchi...',
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
            'Note Aggiuntive (Opzionale)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _injuryNotesController,
            maxLines: 3,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Dettagli aggiuntivi...',
              fillColor: CleanTheme.surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),
          CleanButton(text: 'Salva Infortunio', onPressed: _addInjury),
        ],
      ),
    );
  }

  Widget _buildDurationPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Durata Sessione',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Quanto tempo hai per allenarti?',
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
                    overlayColor: CleanTheme.primaryColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  child: Slider(
                    value: _sessionDuration.toDouble(),
                    min: 30,
                    max: 120,
                    divisions: 9,
                    onChanged: (value) =>
                        setState(() => _sessionDuration = value.toInt()),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CleanButton(text: 'Continua', onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildCardioMobilityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cardio & Mobilità',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          Text('Cardio', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...CardioPreference.values
              .where((p) => p != CardioPreference.separateSession)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CleanCard(
                    isSelected: _cardioPreference == p,
                    onTap: () => setState(() => _cardioPreference = p),
                    child: Row(
                      children: [
                        Text(p.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Text(
                          p.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 32),
          Text('Mobilità', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ...MobilityPreference.values
              .where((p) => p != MobilityPreference.dedicatedSession)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CleanCard(
                    isSelected: _mobilityPreference == p,
                    onTap: () => setState(() => _mobilityPreference = p),
                    child: Row(
                      children: [
                        Text(p.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Text(
                          p.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 24),
          CleanButton(text: 'Continua', onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildTrainingSplitPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Split di Allenamento',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Come vuoi organizzare i tuoi allenamenti?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: TrainingSplit.values.map((split) {
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
                        Text(split.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                split.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                split.description,
                                style: Theme.of(context).textTheme.bodyMedium,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalNotesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ultimi dettagli',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Qualcos\'altro da sapere?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cosa potresti scrivere qui:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: CleanTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Removed: Allergie o intolleranze alimentari
                _buildBulletPoint('Preferenze su esercizi specifici'),
                _buildBulletPoint('Obiettivi particolari non menzionati'),
                _buildBulletPoint('Note mediche aggiuntive'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _prefNotesController,
            maxLines: 5,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Scrivi qui le tue note...',
              fillColor: CleanTheme.surfaceColor,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Spacer(),
          CleanButton(
            text: _isLoading ? 'Salvataggio...' : 'Procedi',
            onPressed: _isLoading ? null : _finish,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        return 'Aumento Massa';
      case FitnessGoal.weightLoss:
        return 'Perdita Peso';
      case FitnessGoal.toning:
        return 'Definizione';
      case FitnessGoal.strength:
        return 'Forza e Potenza';
      case FitnessGoal.wellness:
        return 'Salute e Benessere';
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
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzato';
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
        return 'Palestra';
      case TrainingLocation.home:
        return 'Casa';
      case TrainingLocation.outdoor:
        return 'Outdoor';
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
        return 'Strappi, contratture';
      case InjuryCategory.articular:
        return 'Distorsioni, infiammazioni';
      case InjuryCategory.bone:
        return 'Fratture';
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Forza';
      case WorkoutType.hypertrophy:
        return 'Ipertrofia';
      case WorkoutType.endurance:
        return 'Resistenza';
      case WorkoutType.functional:
        return 'Funzionale';
      case WorkoutType.calisthenics:
        return 'Calisthenics';
    }
  }

  String _getWorkoutTypeDescription(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return 'Massimizza la forza con carichi pesanti e basse ripetizioni.';
      case WorkoutType.hypertrophy:
        return 'Focus sulla crescita muscolare e volume.';
      case WorkoutType.endurance:
        return 'Migliora la resistenza muscolare e cardiovascolare.';
      case WorkoutType.functional:
        return 'Movimenti multi-articolari per la vita quotidiana.';
      case WorkoutType.calisthenics:
        return 'Allenamento a corpo libero per forza e controllo.';
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

  Widget _buildWeeklyFrequencyPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequenza Settimanale',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Quante volte vuoi allenarti a settimana?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 48),

          // Frequency Slider
          Center(
            child: Column(
              children: [
                Text(
                  '$_weeklyFrequency giorni',
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
                    onChanged: (value) =>
                        setState(() => _weeklyFrequency = value.toInt()),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          CleanButton(text: 'Continua', onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildWorkoutTypePage() {
    return _buildSelectionPage(
      title: 'Tipo di Allenamento',
      subtitle: 'Come preferisci allenarti?',
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi sei?', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Per personalizzare il tuo piano.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Gender Selection
          Text('Sesso', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: Gender.values.map((g) {
              final isSelected = _selectedGender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = g),
                  child: Container(
                    margin: EdgeInsets.only(right: g == Gender.male ? 16 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CleanTheme.primaryColor.withValues(alpha: 0.2)
                          : CleanTheme.surfaceColor,
                      border: Border.all(
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.borderPrimary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          g == Gender.male ? Icons.male : Icons.female,
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.textTertiary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g == Gender.male ? 'Uomo' : 'Donna',
                          style: TextStyle(
                            color: isSelected
                                ? CleanTheme.primaryColor
                                : CleanTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Age Input
          Text('Età', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _age?.toString(),
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(color: CleanTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Es. 25',
              hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
              filled: true,
              fillColor: CleanTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CleanTheme.primaryColor),
              ),
              suffixText: 'anni',
              suffixStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
            onChanged: (value) => setState(() {
              _age = int.tryParse(value);
            }),
          ),
          const SizedBox(height: 24),
          CleanButton(
            text: 'Continua',
            onPressed: (_selectedGender != null && _age != null)
                ? _nextPage
                : null,
          ),
        ],
      ),
    );
  }

  // --- Professional Trainer Page Builders ---

  Widget _buildBodyFatPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stima la tua % di grasso',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli l\'immagine che più ti assomiglia.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: BodyFatPercentage.values.map((bf) {
                String title;
                String subtitle;
                String percentage;
                IconData icon;

                switch (bf) {
                  case BodyFatPercentage.veryHigh:
                    title = 'Sovrappeso evidente';
                    subtitle = 'Addome predominante';
                    percentage = 'Molto Alta (>25%)';
                    icon = Icons.accessibility_new;
                    break;
                  case BodyFatPercentage.high:
                    title = 'Sovrappeso leggero';
                    subtitle = 'Poca definizione';
                    percentage = 'Alta (20-25%)';
                    icon = Icons.accessibility;
                    break;
                  case BodyFatPercentage.average:
                    title = 'Normopeso';
                    subtitle = 'Addome piatto';
                    percentage = 'Media (15-20%)';
                    icon = Icons.person;
                    break;
                  case BodyFatPercentage.athletic:
                    title = 'Atletico';
                    subtitle = 'Muscoli visibili';
                    percentage = 'Atletica (10-15%)';
                    icon = Icons.fitness_center;
                    break;
                  case BodyFatPercentage.veryLean:
                    title = 'Molto Definito';
                    subtitle = 'Addominali scolpiti';
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreferencePage() {
    return _buildSelectionPage(
      title: 'Quando preferisci allenarti?',
      subtitle: 'Ottimizzeremo il riscaldamento in base all\'orario.',
      options: TimePreference.values.map((t) {
        String label;
        String description;
        IconData icon;

        switch (t) {
          case TimePreference.morning:
            label = 'Mattina (6:00 - 10:00)';
            description = 'Energia per la giornata, focus mobilità';
            icon = Icons.wb_sunny;
            break;
          case TimePreference.afternoon:
            label = 'Pomeriggio (14:00 - 18:00)';
            description = 'Picco di performance fisica';
            icon = Icons.access_time;
            break;
          case TimePreference.evening:
            label = 'Sera (18:00 - 22:00)';
            description = 'Scarico stress, attenzione al sonno';
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sonno e Recupero',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Fondamentale per calcolare il volume di allenamento.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // Sleep Slider
          Text(
            'Ore di sonno per notte: $_sleepHours',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            value: _sleepHours.toDouble(),
            min: 4,
            max: 10,
            divisions: 6,
            label: _sleepHours.toString(),
            activeColor: CleanTheme.primaryColor,
            onChanged: (val) => setState(() => _sleepHours = val.round()),
          ),

          const SizedBox(height: 32),

          // Recovery Capacity
          Text(
            'Come ti senti solitamente?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: RecoveryCapacity.values.map((r) {
                String label;
                String description;

                switch (r) {
                  case RecoveryCapacity.excellent:
                    label = 'Eccellente';
                    description = 'Mi sveglio riposato, recupero velocemente';
                    break;
                  case RecoveryCapacity.good:
                    label = 'Buono';
                    description = 'Recupero normale, stanchezza occasionale';
                    break;
                  case RecoveryCapacity.poor:
                    label = 'Scarso';
                    description = 'Fatico a recuperare, spesso stanco';
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
                            style: Theme.of(context).textTheme.headlineMedium,
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
            ),
          ),

          CleanButton(
            text: 'Continua',
            onPressed: (_recoveryCapacity != null) ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionApproachPage() {
    return _buildSelectionPage(
      title: 'Alimentazione',
      subtitle: 'Come gestisci la tua dieta?',
      options: NutritionApproach.values.map((n) {
        String label;
        String description;
        IconData icon;

        switch (n) {
          case NutritionApproach.fullTracking:
            label = 'Tracciamento Completo';
            description = 'Conto calorie e macro (MyFitnessPal, ecc.)';
            icon = Icons.calculate;
            break;
          case NutritionApproach.partialTracking:
            label = 'Tracciamento Parziale';
            description = 'Controllo le porzioni e le proteine';
            icon = Icons.pie_chart;
            break;
          case NutritionApproach.intuitive:
            label = 'Mangio Sano';
            description = 'Scelte salutari ma senza tracciare';
            icon = Icons.restaurant;
            break;
          case NutritionApproach.none:
            label = 'Non ci faccio caso';
            description = 'Mangio quello che capita';
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

  Widget _buildTrainingHistoryPage() {
    return _buildSelectionPage(
      title: 'Storico Allenamento',
      subtitle: 'Quanto sei stato costante negli ultimi 6 mesi?',
      options: TrainingHistory.values.map((h) {
        String label;
        String description;
        IconData icon;

        switch (h) {
          case TrainingHistory.veryConsistent:
            label = 'Molto Costante';
            description = '3-6 allenamenti/settimana, raramente saltati';
            icon = Icons.check_circle;
            break;
          case TrainingHistory.somewhatConsistent:
            label = 'Abbastanza Costante';
            description = '2-4 allenamenti/settimana, qualche pausa';
            icon = Icons.check;
            break;
          case TrainingHistory.inconsistent:
            label = 'Incostante';
            description = '1-2 allenamenti/settimana, pause frequenti';
            icon = Icons.warning_amber;
            break;
          case TrainingHistory.inactive:
            label = 'Inattivo';
            description = 'Non mi alleno da 3+ mesi';
            icon = Icons.bed;
            break;
        }

        return _Option(
          label: label,
          description: description,
          icon: icon,
          isSelected: _trainingHistory == h,
          onTap: () {
            setState(() => _trainingHistory = h);
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
