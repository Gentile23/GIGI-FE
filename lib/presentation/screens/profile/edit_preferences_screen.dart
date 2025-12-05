import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/training_preferences_model.dart';
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
  FitnessGoal? _goal;
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
  BodyShape? _bodyShape;

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
            (e) => e.toString().split('.').last == user.gender,
            orElse: () => Gender.male,
          );
        }

        if (user.bodyShape != null) {
          _bodyShape = BodyShape.values.firstWhere(
            (e) => e.toString().split('.').last == user.bodyShape,
            orElse: () => BodyShape.average,
          );
        }

        if (user.goal != null) {
          _goal = FitnessGoal.values.firstWhere(
            (e) => e.toString().split('.').last == user.goal,
            orElse: () => FitnessGoal.wellness,
          );
        }

        if (user.experienceLevel != null) {
          _level = ExperienceLevel.values.firstWhere(
            (e) => e.toString().split('.').last == user.experienceLevel,
            orElse: () => ExperienceLevel.beginner,
          );
        }

        _weeklyFrequency = user.weeklyFrequency;

        if (user.trainingLocation != null) {
          _location = TrainingLocation.values.firstWhere(
            (e) => e.toString().split('.').last == user.trainingLocation,
            orElse: () => TrainingLocation.gym,
          );
        }

        if (user.availableEquipment != null) {
          _equipment = user.availableEquipment!
              .map(
                (e) => Equipment.values.firstWhere(
                  (eq) => eq.toString().split('.').last == e,
                  orElse: () => Equipment.bodyweight,
                ),
              )
              .toList();
        }

        if (user.trainingSplit != null) {
          _trainingSplit = TrainingSplit.values.firstWhere(
            (e) => e.toString().split('.').last == user.trainingSplit,
            orElse: () => TrainingSplit.multifrequency,
          );
        }

        _sessionDuration = user.sessionDuration;

        if (user.cardioPreference != null) {
          _cardioPreference = CardioPreference.values.firstWhere(
            (e) => e.toString().split('.').last == user.cardioPreference,
            orElse: () => CardioPreference.none,
          );
        }

        if (user.mobilityPreference != null) {
          _mobilityPreference = MobilityPreference.values.firstWhere(
            (e) => e.toString().split('.').last == user.mobilityPreference,
            orElse: () => MobilityPreference.postWorkout,
          );
        }

        if (user.workoutType != null) {
          _workoutType = WorkoutType.values.firstWhere(
            (e) => e.toString().split('.').last == user.workoutType,
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
        bodyShape: _bodyShape?.toString().split('.').last,
        goal: _goal?.toString().split('.').last,
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
            const SnackBar(
              content: Text('Preferenze salvate con successo'),
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
                authProvider.error ?? 'Errore durante il salvataggio',
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
              ? 'Rivedi Preferenze'
              : 'Modifica Preferenze',
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
                        'Rivedi le tue preferenze prima di generare il piano. Puoi modificarle se necessario.',
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
            _buildSectionTitle('Informazioni Personali'),
            CleanCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Altezza',
                    '${_height?.toStringAsFixed(0) ?? '-'} cm',
                  ),
                  _buildInfoRow(
                    'Peso',
                    '${_weight?.toStringAsFixed(0) ?? '-'} kg',
                  ),
                  _buildInfoRow('Età', '${_age ?? '-'} anni'),
                  _buildInfoRow('Genere', _getGenderLabel(_gender)),
                  _buildInfoRow('Forma Fisica', _getBodyShapeLabel(_bodyShape)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Training Goals Section
            _buildSectionTitle('Obiettivi di Allenamento'),
            _buildDropdown<FitnessGoal>(
              label: 'Obiettivo',
              value: _goal,
              items: FitnessGoal.values,
              itemLabel: _getGoalLabel,
              onChanged: (value) => setState(() => _goal = value),
            ),
            _buildDropdown<ExperienceLevel>(
              label: 'Livello di Esperienza',
              value: _level,
              items: ExperienceLevel.values,
              itemLabel: _getLevelLabel,
              onChanged: (value) => setState(() => _level = value),
            ),
            _buildSlider(
              label: 'Frequenza Settimanale',
              value: _weeklyFrequency?.toDouble() ?? 3,
              min: 1,
              max: 7,
              divisions: 6,
              suffix: 'giorni/settimana',
              onChanged: (value) =>
                  setState(() => _weeklyFrequency = value.toInt()),
            ),
            const SizedBox(height: 24),

            // Training Location Section
            _buildSectionTitle('Luogo di Allenamento'),
            _buildDropdown<TrainingLocation>(
              label: 'Dove ti alleni?',
              value: _location,
              items: TrainingLocation.values,
              itemLabel: _getLocationLabel,
              onChanged: (value) => setState(() => _location = value),
            ),
            _buildEquipmentSelector(),
            const SizedBox(height: 24),

            // Training Preferences Section
            _buildSectionTitle('Preferenze di Allenamento'),
            _buildDropdown<WorkoutType>(
              label: 'Tipo di Allenamento',
              value: _workoutType,
              items: WorkoutType.values,
              itemLabel: _getWorkoutTypeLabel,
              onChanged: (value) => setState(() => _workoutType = value),
            ),
            _buildDropdown<TrainingSplit>(
              label: 'Split di Allenamento',
              value: _trainingSplit,
              items: TrainingSplit.values,
              itemLabel: (split) => split.displayName,
              onChanged: (value) => setState(() => _trainingSplit = value),
            ),
            _buildSlider(
              label: 'Durata Sessione',
              value: _sessionDuration?.toDouble() ?? 60,
              min: 30,
              max: 120,
              divisions: 9,
              suffix: 'minuti',
              onChanged: (value) =>
                  setState(() => _sessionDuration = value.toInt()),
            ),
            _buildDropdown<CardioPreference>(
              label: 'Preferenza Cardio',
              value: _cardioPreference,
              items: CardioPreference.values,
              itemLabel: (pref) => pref.displayName,
              onChanged: (value) => setState(() => _cardioPreference = value),
            ),
            _buildDropdown<MobilityPreference>(
              label: 'Preferenza Mobilità',
              value: _mobilityPreference,
              items: MobilityPreference.values,
              itemLabel: (pref) => pref.displayName,
              onChanged: (value) => setState(() => _mobilityPreference = value),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (widget.showGenerateButton) ...[
              CleanButton(
                text: 'Genera Piano con Queste Preferenze',
                width: double.infinity,
                onPressed: _isLoading ? null : widget.onGenerate,
              ),
              const SizedBox(height: 12),
              CleanButton(
                text: 'Salva Modifiche',
                width: double.infinity,
                isOutlined: true,
                onPressed: _isLoading ? null : _savePreferences,
              ),
            ] else ...[
              CleanButton(
                text: 'Salva Preferenze',
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
        value: value,
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

  Widget _buildEquipmentSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attrezzatura Disponibile',
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
    if (gender == null) return 'Non specificato';
    return gender == Gender.male ? 'Maschio' : 'Femmina';
  }

  String _getBodyShapeLabel(BodyShape? shape) {
    if (shape == null) return 'Non specificato';
    switch (shape) {
      case BodyShape.skinny:
        return 'Molto Magro';
      case BodyShape.lean:
        return 'Magro';
      case BodyShape.athletic:
        return 'Atletico';
      case BodyShape.muscular:
        return 'Muscoloso';
      case BodyShape.overweight:
        return 'Sovrappeso';
      case BodyShape.average:
        return 'Medio';
    }
  }

  String _getGoalLabel(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.muscleGain:
        return 'Aumento Massa Muscolare';
      case FitnessGoal.weightLoss:
        return 'Perdita di Peso';
      case FitnessGoal.toning:
        return 'Tonificazione';
      case FitnessGoal.strength:
        return 'Forza';
      case FitnessGoal.wellness:
        return 'Benessere';
    }
  }

  String _getLevelLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzato';
    }
  }

  String _getLocationLabel(TrainingLocation location) {
    switch (location) {
      case TrainingLocation.gym:
        return 'Palestra';
      case TrainingLocation.home:
        return 'Casa';
      case TrainingLocation.outdoor:
        return 'All\'aperto';
    }
  }

  String _getEquipmentLabel(Equipment equipment) {
    switch (equipment) {
      case Equipment.bench:
        return 'Panca';
      case Equipment.dumbbells:
        return 'Manubri';
      case Equipment.barbell:
        return 'Bilanciere';
      case Equipment.resistanceBands:
        return 'Bande Elastiche';
      case Equipment.machines:
        return 'Macchine';
      case Equipment.bodyweight:
        return 'Corpo Libero';
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
}
