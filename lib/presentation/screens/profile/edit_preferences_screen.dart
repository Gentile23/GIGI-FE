import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/training_preferences_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/clean_widgets.dart';

class EditPreferencesScreen extends StatefulWidget {
  final bool showGenerateButton;
  final VoidCallback? onGenerate;

  const EditPreferencesScreen({
    super.key,
    this.showGenerateButton = false,
    this.onGenerate,
  });

  @override
  State<EditPreferencesScreen> createState() => _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends State<EditPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // User preferences
  final Set<FitnessGoal> _goals = {};
  ExperienceLevel? _level;
  int? _weeklyFrequency;
  TrainingLocation? _location;
  List<Equipment> _equipment = [];
  TrainingSplit? _trainingSplit;
  int? _sessionDuration;
  CardioPreference? _cardioPreference;
  MobilityPreference? _mobilityPreference;
  WorkoutType? _workoutType;
  double? _height;
  double? _weight;
  Gender? _gender;
  int? _age;
  BodyFatPercentage? _bodyFatPercentage;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  void _loadCurrentPreferences() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _height = user.height;
        _weight = user.weight;

        if (user.dateOfBirth != null) {
          final now = DateTime.now();
          _age = now.year - user.dateOfBirth!.year;
          if (now.month < user.dateOfBirth!.month ||
              (now.month == user.dateOfBirth!.month &&
                  now.day < user.dateOfBirth!.day)) {
            _age = _age! - 1;
          }
        }

        if (user.gender != null) {
          _gender = Gender.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.gender!.toLowerCase(),
            orElse: () => Gender.male,
          );
        }

        if (user.bodyFatPercentage != null) {
          _bodyFatPercentage = user.bodyFatPercentage;
        }

        if (user.goals != null && user.goals!.isNotEmpty) {
          _goals.clear();
          for (final g in user.goals!) {
            try {
              final goal = FitnessGoal.values.firstWhere(
                (e) =>
                    e.toString().split('.').last.toLowerCase() ==
                    g.toLowerCase(),
              );
              _goals.add(goal);
            } catch (_) {}
          }
        } else if (user.goal != null) {
          try {
            final goal = FitnessGoal.values.firstWhere(
              (e) =>
                  e.toString().split('.').last.toLowerCase() ==
                  user.goal!.toLowerCase(),
            );
            _goals.add(goal);
          } catch (_) {}
        }

        if (user.experienceLevel != null) {
          _level = ExperienceLevel.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.experienceLevel!.toLowerCase(),
            orElse: () => ExperienceLevel.beginner,
          );
        }

        _weeklyFrequency = user.weeklyFrequency;

        if (user.trainingLocation != null) {
          _location = TrainingLocation.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.trainingLocation!.toLowerCase(),
            orElse: () => TrainingLocation.gym,
          );
        }

        if (user.availableEquipment != null) {
          _equipment = user.availableEquipment!
              .map(
                (e) => Equipment.values.firstWhere(
                  (eq) =>
                      eq.toString().split('.').last.toLowerCase() ==
                      e.toLowerCase(),
                  orElse: () => Equipment.bodyweight,
                ),
              )
              .toList();
        }

        if (user.trainingSplit != null) {
          _trainingSplit = TrainingSplit.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.trainingSplit!.toLowerCase(),
            orElse: () => TrainingSplit.multifrequency,
          );
        }

        _sessionDuration = user.sessionDuration;

        if (user.cardioPreference != null) {
          _cardioPreference = CardioPreference.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.cardioPreference!.toLowerCase(),
            orElse: () => CardioPreference.none,
          );
        }

        if (user.mobilityPreference != null) {
          _mobilityPreference = MobilityPreference.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.mobilityPreference!.toLowerCase(),
            orElse: () => MobilityPreference.postWorkout,
          );
        }

        if (user.workoutType != null) {
          _workoutType = WorkoutType.values.firstWhere(
            (e) =>
                e.toString().split('.').last.toLowerCase() ==
                user.workoutType!.toLowerCase(),
            orElse: () => WorkoutType.hypertrophy,
          );
        }
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.updateProfile(
        height: _height,
        weight: _weight,
        age: _age,
        gender: _gender?.toString().split('.').last,
        bodyFatPercentage: _camelToSnake(
          _bodyFatPercentage?.toString().split('.').last,
        ),
        goals: _goals.map((g) => g.toString().split('.').last).toList(),
        goal: _goals.isNotEmpty
            ? _goals.first.toString().split('.').last
            : null, // Backward compatibility
        level: _level?.toString().split('.').last,
        weeklyFrequency: _weeklyFrequency,
        location: _location?.toString().split('.').last,
        equipment: _equipment.map((e) => e.toString().split('.').last).toList(),
        trainingSplit: _trainingSplit?.toString().split('.').last,
        sessionDuration: _sessionDuration,
        cardioPreference: _cardioPreference?.toString().split('.').last,
        mobilityPreference: _mobilityPreference?.toString().split('.').last,
        workoutType: _workoutType?.toString().split('.').last,
        silent: true,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.preferencesSavedSuccess,
              ),
              backgroundColor: CleanTheme.primaryColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error ??
                    AppLocalizations.of(context)!.errorSavingPreferences,
              ),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
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
      appBar: AppBar(
        title: Text(
          widget.showGenerateButton
              ? AppLocalizations.of(context)!.reviewPreferences
              : AppLocalizations.of(context)!.editPreferences,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.showGenerateButton) ...[
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: CleanTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.reviewPreferencesDesc,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Personal Info Section
            _buildSectionTitle(AppLocalizations.of(context)!.personalInfo),
            CleanCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    AppLocalizations.of(context)!.height,
                    '${_height?.toStringAsFixed(0) ?? '-'} cm',
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.weight,
                    '${_weight?.toStringAsFixed(0) ?? '-'} kg',
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.age,
                    '${_age ?? '-'} ${AppLocalizations.of(context)!.years}',
                  ),
                  _buildInfoRow(
                    AppLocalizations.of(context)!.gender,
                    _getGenderLabel(_gender),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown<BodyFatPercentage>(
              label: AppLocalizations.of(context)!.bodyShape,
              value: _bodyFatPercentage,
              items: BodyFatPercentage.values,
              itemLabel: _getBodyFatLabel,
              onChanged: (value) => setState(() => _bodyFatPercentage = value),
            ),
            const SizedBox(height: 24),

            // Training Goals Section
            _buildSectionTitle(AppLocalizations.of(context)!.trainingGoals),
            _buildGoalsSelector(), // NEW: Multi-select
            _buildDropdown<ExperienceLevel>(
              label: AppLocalizations.of(context)!.experienceLevel,
              value: _level,
              items: ExperienceLevel.values,
              itemLabel: _getLevelLabel,
              onChanged: (value) => setState(() => _level = value),
            ),
            _buildSlider(
              label: AppLocalizations.of(context)!.weeklyFrequency,
              value: _weeklyFrequency?.toDouble() ?? 3,
              min: 1,
              max: 7,
              divisions: 6,
              suffix: AppLocalizations.of(context)!.daysPerWeek,
              onChanged: (value) =>
                  setState(() => _weeklyFrequency = value.toInt()),
            ),
            const SizedBox(height: 24),

            // Training Location Section
            _buildSectionTitle(AppLocalizations.of(context)!.trainingLocation),
            _buildDropdown<TrainingLocation>(
              label: AppLocalizations.of(context)!.whereDoYouTrain,
              value: _location,
              items: TrainingLocation.values,
              itemLabel: _getLocationLabel,
              onChanged: (value) => setState(() => _location = value),
            ),
            _buildEquipmentSelector(),
            const SizedBox(height: 24),

            // Training Preferences Section
            _buildSectionTitle(
              AppLocalizations.of(context)!.trainingPreferences,
            ),
            _buildDropdown<WorkoutType>(
              label: AppLocalizations.of(context)!.workoutType,
              value: _workoutType,
              items: WorkoutType.values,
              itemLabel: _getWorkoutTypeLabel,
              onChanged: (value) => setState(() => _workoutType = value),
            ),
            _buildDropdown<TrainingSplit>(
              label: AppLocalizations.of(context)!.trainingSplit,
              value: _trainingSplit,
              items: TrainingSplit.values,
              itemLabel: (split) => split.displayName,
              onChanged: (value) => setState(() => _trainingSplit = value),
            ),
            _buildSlider(
              label: AppLocalizations.of(context)!.sessionDuration,
              value: _sessionDuration?.toDouble() ?? 60,
              min: 30,
              max: 120,
              divisions: 9,
              suffix: AppLocalizations.of(context)!.minutes,
              onChanged: (value) =>
                  setState(() => _sessionDuration = value.toInt()),
            ),
            _buildDropdown<CardioPreference>(
              label: AppLocalizations.of(context)!.cardioPreference,
              value: _cardioPreference,
              items: CardioPreference.values,
              itemLabel: (pref) => pref.displayName,
              onChanged: (value) => setState(() => _cardioPreference = value),
            ),
            _buildDropdown<MobilityPreference>(
              label: AppLocalizations.of(context)!.mobilityPreference,
              value: _mobilityPreference,
              items: MobilityPreference.values,
              itemLabel: (pref) => pref.displayName,
              onChanged: (value) => setState(() => _mobilityPreference = value),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (widget.showGenerateButton) ...[
              CleanButton(
                text: AppLocalizations.of(context)!.generatePlanWithPrefs,
                width: double.infinity,
                onPressed: _isLoading ? null : widget.onGenerate,
              ),
              const SizedBox(height: 12),
              CleanButton(
                text: AppLocalizations.of(context)!.saveChanges,
                width: double.infinity,
                isOutlined: true,
                onPressed: _isLoading ? null : _savePreferences,
              ),
            ] else ...[
              CleanButton(
                text: AppLocalizations.of(context)!.savePreferences,
                width: double.infinity,
                onPressed: _isLoading ? null : _savePreferences,
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CleanTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        style: GoogleFonts.inter(color: CleanTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
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
            borderSide: const BorderSide(
              color: CleanTheme.primaryColor,
              width: 2,
            ),
          ),
        ),
        dropdownColor: CleanTheme.surfaceColor,
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item, child: Text(itemLabel(item))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required void Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
              Text(
                '${value.toInt()} $suffix',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: CleanTheme.primaryColor,
            inactiveColor: CleanTheme.borderSecondary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.goal,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FitnessGoal.values.map((goal) {
              final isSelected = _goals.contains(goal);
              return FilterChip(
                label: Text(
                  _getGoalLabel(goal),
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : CleanTheme.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: CleanTheme.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: CleanTheme.surfaceColor,
                side: BorderSide(
                  color: isSelected
                      ? CleanTheme.primaryColor
                      : CleanTheme.borderPrimary,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      // Exclusive logic if needed (e.g. WeightLoss vs MuscleGain)
                      // For now, mirroring unified_questionnaire logic if desired,
                      // or allowing full multi-select.
                      // UnifiedQuestionnaire enforces some exclusivity:
                      if (goal == FitnessGoal.weightLoss) {
                        _goals.remove(FitnessGoal.muscleGain);
                      } else if (goal == FitnessGoal.muscleGain) {
                        _goals.remove(FitnessGoal.weightLoss);
                      }
                      _goals.add(goal);
                    } else {
                      _goals.remove(goal);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.availableEquipment,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Equipment.values.map((eq) {
              final isSelected = _equipment.contains(eq);
              return FilterChip(
                label: Text(
                  _getEquipmentLabel(eq),
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : CleanTheme.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: CleanTheme.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: CleanTheme.surfaceColor,
                side: BorderSide(
                  color: isSelected
                      ? CleanTheme.primaryColor
                      : CleanTheme.borderPrimary,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _equipment.add(eq);
                    } else {
                      _equipment.remove(eq);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getGenderLabel(Gender? gender) {
    if (gender == null) return AppLocalizations.of(context)!.unspecified;
    return gender == Gender.male
        ? AppLocalizations.of(context)!.male
        : AppLocalizations.of(context)!.female;
  }

  String _getBodyFatLabel(BodyFatPercentage? bodyFat) {
    if (bodyFat == null) return AppLocalizations.of(context)!.unspecified;
    switch (bodyFat) {
      case BodyFatPercentage.veryHigh:
        return 'Evidente sovrappeso (20-25%+)';
      case BodyFatPercentage.high:
        return 'Sovrappeso leggero (15-20%)';
      case BodyFatPercentage.average:
        return 'Normale (10-15%)';
      case BodyFatPercentage.athletic:
        return 'Atletico (6-10%)';
      case BodyFatPercentage.veryLean:
        return 'Molto magro (<6%)';
    }
  }

  String _camelToSnake(String? value) {
    if (value == null) return '';
    return value
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .toLowerCase();
  }

  String _getGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.muscleGain:
        return AppLocalizations.of(context)!.muscleGain;
      case FitnessGoal.weightLoss:
        return AppLocalizations.of(context)!.weightLoss;
      case FitnessGoal.toning:
        return AppLocalizations.of(context)!.toning;
      case FitnessGoal.strength:
        return AppLocalizations.of(context)!.strength;
      case FitnessGoal.wellness:
        return AppLocalizations.of(context)!.wellness;
    }
  }

  String _getLevelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return AppLocalizations.of(context)!.beginner;
      case ExperienceLevel.intermediate:
        return AppLocalizations.of(context)!.intermediate;
      case ExperienceLevel.advanced:
        return AppLocalizations.of(context)!.advanced;
    }
  }

  String _getLocationLabel(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return AppLocalizations.of(context)!.gym;
      case TrainingLocation.home:
        return AppLocalizations.of(context)!.home;
      case TrainingLocation.outdoor:
        return AppLocalizations.of(context)!.outdoor;
    }
  }

  String _getEquipmentLabel(Equipment equipment) {
    switch (equipment) {
      case Equipment.bench:
        return AppLocalizations.of(context)!.bench;
      case Equipment.dumbbells:
        return AppLocalizations.of(context)!.dumbbells;
      case Equipment.barbell:
        return AppLocalizations.of(context)!.barbell;
      case Equipment.resistanceBands:
        return AppLocalizations.of(context)!.resistanceBands;
      case Equipment.machines:
        return AppLocalizations.of(context)!.machines;
      case Equipment.bodyweight:
        return AppLocalizations.of(context)!.bodyweight;
    }
  }

  String _getWorkoutTypeLabel(WorkoutType type) {
    switch (type) {
      case WorkoutType.strength:
        return AppLocalizations.of(context)!.strength;
      case WorkoutType.hypertrophy:
        return AppLocalizations.of(context)!.ipertrofia;
      case WorkoutType.endurance:
        return AppLocalizations.of(context)!.endurance;
      case WorkoutType.functional:
        return AppLocalizations.of(context)!.functional;
      case WorkoutType.calisthenics:
        return AppLocalizations.of(context)!.calisthenics;
    }
  }
}
