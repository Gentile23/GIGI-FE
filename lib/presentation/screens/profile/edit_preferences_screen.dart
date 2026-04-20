import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/training_preferences_model.dart';
import '../../../data/models/injury_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';

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
  final _nameController = TextEditingController();
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
  double? _height;
  double? _weight;
  Gender? _gender;
  int? _age;
  DateTime? _dateOfBirth;
  BodyFatPercentage? _bodyFatPercentage;
  List<InjuryModel> _injuries = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _loadCurrentPreferences() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _nameController.text = user.name;
        _height = user.height;
        _weight = user.weight;
        _injuries = List<InjuryModel>.from(user.detailedInjuries);

        if (user.dateOfBirth != null) {
          _dateOfBirth = user.dateOfBirth;
          final now = DateTime.now();
          _age = now.year - _dateOfBirth!.year;
          if (now.month < _dateOfBirth!.month ||
              (now.month == _dateOfBirth!.month &&
                  now.day < _dateOfBirth!.day)) {
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
      });
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final detailedInjuries = _injuries.map((i) => i.toJson()).toList();
      final limitations = _injuries
          .map(
            (i) =>
                '${i.category.getLocalizedName(context)}: ${i.area.getLocalizedName(context)} (${i.severity.getLocalizedName(context)})',
          )
          .toList();

      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        height: _height,
        weight: _weight,
        dateOfBirth: _dateOfBirth?.toIso8601String().split('T')[0],
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
        limitations: limitations,
        detailedInjuries: detailedInjuries,
        trainingSplit: _trainingSplit?.toString().split('.').last,
        sessionDuration: _sessionDuration,
        cardioPreference: _cardioPreference?.toString().split('.').last,
        mobilityPreference: _mobilityPreference?.toString().split('.').last,
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
          const SnackBar(
            content: Text(
              'Si è verificato un errore durante il salvataggio. Riprova.',
            ),
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
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showGenerateButton) _buildInstructionsCard(),

                    _buildGigiHeader(
                      'Profilo Fitness',
                      'Dati personali, obiettivi, preferenze e infortuni',
                    ),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 24),
                    _buildBodyFatSelector(),
                    const SizedBox(height: 24),
                    _buildGoalsSelector(),
                    const SizedBox(height: 24),
                    _buildExperienceLevelSelector(),
                    const SizedBox(height: 24),
                    _buildFrequencySlider(),

                    const SizedBox(height: 32),
                    _buildGigiHeader(
                      AppLocalizations.of(context)!.trainingLocation,
                      AppLocalizations.of(context)!.questionLocationSubtitle,
                    ),
                    _buildLocationSelector(),
                    const SizedBox(height: 24),
                    _buildEquipmentSelector(),

                    const SizedBox(height: 32),
                    _buildGigiHeader(
                      AppLocalizations.of(context)!.trainingPreferences,
                      'Personalizza il tuo stile di allenamento',
                    ),
                    _buildSplitSelector(),
                    const SizedBox(height: 24),
                    _buildDurationSlider(),
                    const SizedBox(height: 24),
                    _buildCardioMobilitySelectors(),
                    const SizedBox(height: 32),
                    _buildInjuriesSection(),

                    const SizedBox(height: 48),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: CleanTheme.surfaceColor,
      title: Text(
        widget.showGenerateButton
            ? AppLocalizations.of(context)!.reviewPreferences
            : 'Profilo Fitness',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          color: CleanTheme.textPrimary,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: CleanTheme.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildGigiHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: CleanTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: LiquidSteelContainer(
        borderRadius: 20,
        enableShine: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: CleanTheme.textOnDark),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.reviewPreferencesDesc,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textOnDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return CleanCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildEditableTextInfoTile(
            label: AppLocalizations.of(context)!.fullName,
            icon: Icons.person_outline,
            controller: _nameController,
            hintText: AppLocalizations.of(context)!.enterYourName,
          ),
          _buildDivider(),
          _buildInfoTile(
            AppLocalizations.of(context)!.height,
            '${_height?.toStringAsFixed(0) ?? '-'} cm',
            Icons.height,
            onTap: () => _showNumberPicker(
              AppLocalizations.of(context)!.height,
              _height?.toInt() ?? 170,
              100,
              250,
              'cm',
              (v) => setState(() => _height = v.toDouble()),
            ),
          ),
          _buildDivider(),
          _buildInfoTile(
            AppLocalizations.of(context)!.weight,
            '${_weight?.toStringAsFixed(0) ?? '-'} kg',
            Icons.monitor_weight_outlined,
            onTap: () => _showNumberPicker(
              AppLocalizations.of(context)!.weight,
              _weight?.toInt() ?? 70,
              30,
              200,
              'kg',
              (v) => setState(() => _weight = v.toDouble()),
            ),
          ),
          _buildDivider(),
          _buildInfoTile(
            AppLocalizations.of(context)!.age,
            _dateOfBirth != null
                ? '${_age ?? '-'} ${AppLocalizations.of(context)!.years}'
                : 'Seleziona data',
            Icons.cake_outlined,
            onTap: _showDatePicker,
          ),
          _buildDivider(),
          _buildInfoTile(
            AppLocalizations.of(context)!.gender,
            _getGenderLabel(_gender),
            Icons.person_pin_outlined,
            onTap: () => _showPrefPicker<Gender>(
              AppLocalizations.of(context)!.gender,
              Gender.values,
              _gender,
              (v) => setState(() => _gender = v),
              itemLabel: (g) => _getGenderLabel(g),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CleanTheme.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: CleanTheme.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextInfoTile({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: CleanTheme.textSecondary),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textTertiary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.enterYourName;
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: CleanTheme.borderSecondary,
      indent: 52,
    );
  }

  Widget _buildBodyFatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.bodyShape,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: BodyFatPercentage.values.map((bf) {
              final isSelected = _bodyFatPercentage == bf;
              return CleanChip(
                label: _getBodyFatLabel(bf),
                isSelected: isSelected,
                onTap: () {
                  HapticService.lightTap();
                  setState(() => _bodyFatPercentage = bf);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.experienceLevel,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ExperienceLevel.values.map((lvl) {
              final isSelected = _level == lvl;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 100, // Fixed width for centering
                  child: CleanCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    isSelected: isSelected,
                    onTap: () {
                      HapticService.selectionClick();
                      setState(() => _level = lvl);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getLevelIcon(lvl),
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLevelLabel(lvl),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? CleanTheme.textPrimary
                                : CleanTheme.textSecondary,
                          ),
                        ),
                      ],
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

  IconData _getLevelIcon(ExperienceLevel lvl) {
    switch (lvl) {
      case ExperienceLevel.beginner:
        return Icons.spoke_outlined;
      case ExperienceLevel.intermediate:
        return Icons.trending_up;
      case ExperienceLevel.advanced:
        return Icons.workspace_premium;
    }
  }

  Widget _buildFrequencySlider() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.weeklyFrequency,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_weeklyFrequency ?? 3} GIORNI',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              activeTrackColor: CleanTheme.primaryColor,
              inactiveTrackColor: CleanTheme.borderSecondary,
              thumbColor: CleanTheme.textPrimary,
              overlayColor: CleanTheme.primaryColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _weeklyFrequency?.toDouble() ?? 3,
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (value) {
                HapticService.lightTap();
                setState(() => _weeklyFrequency = value.toInt());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: TrainingLocation.values.map((loc) {
          final isSelected = _location == loc;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 100, // Fixed width for centering
              child: CleanCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                isSelected: isSelected,
                onTap: () {
                  HapticService.selectionClick();
                  setState(() => _location = loc);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getLocationIcon(loc),
                      size: 28,
                      color: isSelected
                          ? CleanTheme.primaryColor
                          : CleanTheme.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getLocationLabel(loc),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? CleanTheme.textPrimary
                            : CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getLocationIcon(TrainingLocation loc) {
    switch (loc) {
      case TrainingLocation.gym:
        return Icons.fitness_center;
      case TrainingLocation.home:
        return Icons.home_filled;
      case TrainingLocation.outdoor:
        return Icons.forest;
    }
  }

  Widget _buildSplitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.trainingSplit,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildCustomDropdown<TrainingSplit>(
          value: _trainingSplit,
          items: TrainingSplit.values,
          itemLabel: (split) => split.displayName,
          iconBuilder: (split) => split.icon,
          onChanged: (value) => setState(() => _trainingSplit = value),
        ),
      ],
    );
  }

  Widget _buildCustomDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) iconBuilder,
    required void Function(T?) onChanged,
  }) {
    return CleanCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: CleanTheme.textSecondary,
          ),
          dropdownColor: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Text(iconBuilder(item), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(
                    itemLabel(item),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: CleanTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            HapticService.selectionClick();
            onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.sessionDuration,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
              Text(
                '${_sessionDuration ?? 60} MIN',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: CleanTheme.primaryColor,
              inactiveTrackColor: CleanTheme.borderSecondary,
              thumbColor: CleanTheme.textPrimary,
            ),
            child: Slider(
              value: _sessionDuration?.toDouble() ?? 60,
              min: 30,
              max: 120,
              divisions: 9,
              onChanged: (value) {
                HapticService.lightTap();
                setState(() => _sessionDuration = value.toInt());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardioMobilitySelectors() {
    return Column(
      children: [
        _buildPrefRow(
          AppLocalizations.of(context)!.cardioPreference,
          _cardioPreference?.displayName ?? '-',
          Icons.directions_run,
          () => _showPrefPicker<CardioPreference>(
            AppLocalizations.of(context)!.cardioPreference,
            CardioPreference.values
                .where((p) => p != CardioPreference.separateSession)
                .toList(),
            _cardioPreference,
            (v) => setState(() => _cardioPreference = v),
            itemLabel: (p) => p.displayName,
          ),
        ),
        const SizedBox(height: 16),
        _buildPrefRow(
          AppLocalizations.of(context)!.mobilityPreference,
          _mobilityPreference?.displayName ?? '-',
          Icons.accessibility_new,
          () => _showPrefPicker<MobilityPreference>(
            AppLocalizations.of(context)!.mobilityPreference,
            MobilityPreference.values
                .where((p) => p != MobilityPreference.dedicatedSession)
                .toList(),
            _mobilityPreference,
            (v) => setState(() => _mobilityPreference = v),
            itemLabel: (p) => p.displayName,
          ),
        ),
      ],
    );
  }

  Widget _buildPrefRow(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: CleanTheme.textSecondary, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: CleanTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildInjuriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.injuriesTitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        CleanCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _injuries.isEmpty
                          ? 'Nessun infortunio inserito'
                          : '${_injuries.length} infortun${_injuries.length == 1 ? 'io' : 'i'} registrat${_injuries.length == 1 ? 'o' : 'i'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openInjuryEditor(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Aggiungi'),
                  ),
                ],
              ),
              if (_injuries.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(color: CleanTheme.borderSecondary),
                ...List.generate(_injuries.length, (index) {
                  final injury = _injuries[index];
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          injury.category.icon,
                          color: CleanTheme.primaryColor,
                        ),
                        title: Text(
                          injury.area.getLocalizedName(context),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${injury.severity.getLocalizedName(context)} · ${injury.status.getLocalizedName(context)} · ${_getTimingLabel(injury.timing)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _openInjuryEditor(editIndex: index),
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _injuries.removeAt(index));
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: CleanTheme.accentRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != _injuries.length - 1)
                        const Divider(color: CleanTheme.borderSecondary),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openInjuryEditor({int? editIndex}) {
    final existing = editIndex != null ? _injuries[editIndex] : null;
    final painfulController = TextEditingController(
      text: existing?.painfulExercises ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');

    InjuryCategory selectedCategory =
        existing?.category ?? InjuryCategory.muscular;
    InjuryArea? selectedArea = existing?.area;
    InjuryTiming selectedTiming = existing?.timing ?? InjuryTiming.current;
    InjuryStatus selectedStatus = existing?.status ?? InjuryStatus.active;
    InjurySeverity selectedSeverity = existing?.severity ?? InjurySeverity.mild;
    String selectedSide = existing?.side ?? 'bilateral';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CleanTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final areas = InjuryArea.values
                .where((a) => a.category == selectedCategory)
                .toList();

            if (selectedArea != null && !areas.contains(selectedArea)) {
              selectedArea = null;
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      editIndex == null
                          ? 'Nuovo infortunio'
                          : 'Modifica infortunio',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InjuryCategory>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      items: InjuryCategory.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.getLocalizedName(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          selectedCategory = value;
                          selectedArea = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InjuryArea>(
                      initialValue: selectedArea,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                        border: OutlineInputBorder(),
                      ),
                      items: areas
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(a.getLocalizedName(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() => selectedArea = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InjuryTiming>(
                      initialValue: selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Quando',
                        border: OutlineInputBorder(),
                      ),
                      items: InjuryTiming.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(_getTimingLabel(t)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedTiming = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InjuryStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Stato',
                        border: OutlineInputBorder(),
                      ),
                      items: InjuryStatus.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.getLocalizedName(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InjurySeverity>(
                      initialValue: selectedSeverity,
                      decoration: const InputDecoration(
                        labelText: 'Gravità',
                        border: OutlineInputBorder(),
                      ),
                      items: InjurySeverity.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.getLocalizedName(context)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedSeverity = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (selectedArea != null &&
                        _isSideApplicable(selectedArea!))
                      DropdownButtonFormField<String>(
                        initialValue: selectedSide,
                        decoration: const InputDecoration(
                          labelText: 'Lato',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'left',
                            child: Text('Sinistro'),
                          ),
                          DropdownMenuItem(
                            value: 'right',
                            child: Text('Destro'),
                          ),
                          DropdownMenuItem(
                            value: 'bilateral',
                            child: Text('Bilaterale'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedSide = value);
                        },
                      ),
                    if (selectedArea != null &&
                        _isSideApplicable(selectedArea!))
                      const SizedBox(height: 12),
                    TextFormField(
                      controller: painfulController,
                      decoration: const InputDecoration(
                        labelText: 'Esercizi dolorosi (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Note (opzionale)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CleanButton(
                      text: editIndex == null
                          ? 'Salva infortunio'
                          : 'Aggiorna infortunio',
                      width: double.infinity,
                      onPressed: () {
                        if (selectedArea == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seleziona una zona specifica'),
                              backgroundColor: CleanTheme.accentRed,
                            ),
                          );
                          return;
                        }

                        final injury = InjuryModel(
                          id:
                              existing?.id ??
                              'injury_${DateTime.now().microsecondsSinceEpoch}',
                          category: selectedCategory,
                          area: selectedArea!,
                          severity: selectedSeverity,
                          status: selectedStatus,
                          timing: selectedTiming,
                          side: _isSideApplicable(selectedArea!)
                              ? selectedSide
                              : null,
                          isOvercome: selectedStatus == InjuryStatus.resolved,
                          painfulExercises:
                              painfulController.text.trim().isEmpty
                              ? null
                              : painfulController.text.trim(),
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          reportedAt: existing?.reportedAt ?? DateTime.now(),
                        );

                        setState(() {
                          if (editIndex == null) {
                            _injuries.add(injury);
                          } else {
                            _injuries[editIndex] = injury;
                          }
                        });

                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      painfulController.dispose();
      notesController.dispose();
    });
  }

  bool _isSideApplicable(InjuryArea area) {
    const midlineAreas = {
      InjuryArea.neck,
      InjuryArea.abs,
      InjuryArea.obliques,
      InjuryArea.lowerBack,
      InjuryArea.upperBack,
      InjuryArea.cervicalSpine,
      InjuryArea.thoracicSpine,
      InjuryArea.lumbarSpine,
      InjuryArea.sacroiliac,
      InjuryArea.vertebrae,
      InjuryArea.pelvis,
      InjuryArea.sternum,
      InjuryArea.ribs,
      InjuryArea.temporomandibular,
    };
    return !midlineAreas.contains(area);
  }

  String _getTimingLabel(InjuryTiming timing) {
    switch (timing) {
      case InjuryTiming.current:
        return AppLocalizations.of(context)!.injuryTimingCurrent;
      case InjuryTiming.past:
        return AppLocalizations.of(context)!.injuryTimingPast;
    }
  }

  void _showNumberPicker(
    String title,
    int initialValue,
    int min,
    int max,
    String unit,
    Function(int) onPick,
  ) {
    int currentValue = initialValue;
    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                '$currentValue $unit',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: CleanTheme.primaryColor,
                  inactiveTrackColor: CleanTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  thumbColor: CleanTheme.primaryColor,
                  overlayColor: CleanTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: currentValue.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  onChanged: (value) {
                    HapticService.selectionClick();
                    setModalState(() => currentValue = value.toInt());
                  },
                ),
              ),
              const SizedBox(height: 32),
              CleanButton(
                text: 'Conferma',
                width: double.infinity,
                onPressed: () {
                  onPick(currentValue);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrefPicker<T>(
    String title,
    List<T> items,
    T? current,
    Function(T) onPick, {
    required String Function(T) itemLabel,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...items.map((item) {
              final label = itemLabel(item);
              final isSelected = item == current;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CleanCard(
                  padding: const EdgeInsets.all(20),
                  isSelected: isSelected,
                  onTap: () {
                    HapticService.selectionClick();
                    onPick(item);
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? CleanTheme.textPrimary
                              : CleanTheme.textSecondary,
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
            }),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() {
    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CleanTheme.primaryColor,
              onPrimary: Colors.white,
              surface: CleanTheme.surfaceColor,
              onSurface: CleanTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _dateOfBirth = picked;
          final now = DateTime.now();
          _age = now.year - picked.year;
          if (now.month < picked.month ||
              (now.month == picked.month && now.day < picked.day)) {
            _age = _age! - 1;
          }
        });
      }
    });
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildGoalsSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Obiettivi',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: FitnessGoal.values
                  .where((g) => g != FitnessGoal.toning)
                  .map((goal) {
                    final isSelected = _goals.contains(goal);
                    return CleanChip(
                      label: _getGoalLabel(goal),
                      isSelected: isSelected,
                      onTap: () {
                        HapticService.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _goals.remove(goal);
                          } else {
                            if (goal == FitnessGoal.weightLoss) {
                              _goals.remove(FitnessGoal.muscleGain);
                            } else if (goal == FitnessGoal.muscleGain) {
                              _goals.remove(FitnessGoal.weightLoss);
                            }
                            _goals.add(goal);
                          }
                        });
                      },
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.availableEquipment,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: Equipment.values.map((eq) {
              final isSelected = _equipment.contains(eq);
              return CleanChip(
                label: _getEquipmentLabel(eq),
                isSelected: isSelected,
                onTap: () {
                  HapticService.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _equipment.remove(eq);
                    } else {
                      _equipment.add(eq);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
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
}
