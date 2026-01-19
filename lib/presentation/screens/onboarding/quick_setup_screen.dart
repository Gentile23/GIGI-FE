import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_profile_model.dart';
import 'onboarding_choice_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// QUICK SETUP SCREEN - Complete onboarding with 8 essential steps
/// Psychology: Progressive disclosure + foot-in-the-door technique
/// Steps: Goal → Level → Equipment → Frequency → Height/Weight → Age/Gender → Location → Final Notes
/// ═══════════════════════════════════════════════════════════
class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key});

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;
  bool _isSaving = false;

  // User selections
  FitnessGoal? _selectedGoal;
  ExperienceLevel? _selectedLevel;
  final Set<String> _selectedEquipment = {};
  int _weeklyFrequency = 3;
  final TextEditingController _nameController = TextEditingController();

  // New fields
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  Gender? _selectedGender;
  TrainingLocation? _selectedLocation;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillName();
  }

  void _prefillName() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final name = user?.name;
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      HapticService.lightTap();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _finishSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      HapticService.lightTap();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _finishSetup() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    HapticService.mediumTap();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Parse height and weight
      double? height;
      double? weight;
      int? age;

      if (_heightController.text.isNotEmpty) {
        height = double.tryParse(_heightController.text);
      }
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }
      if (_ageController.text.isNotEmpty) {
        age = int.tryParse(_ageController.text);
      }

      // Save profile with all data
      await authProvider.updateProfile(
        goal: _selectedGoal?.name,
        level: _selectedLevel?.name,
        weeklyFrequency: _weeklyFrequency,
        equipment: _selectedEquipment.toList(),
        height: height,
        weight: weight,
        age: age,
        gender: _selectedGender?.name,
        location: _selectedLocation?.name,
        additionalNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      // Navigate to choice screen (trial workout / measurements / skip)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingChoiceScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // Goal
        return _selectedGoal != null;
      case 1: // Level
        return _selectedLevel != null;
      case 2: // Equipment
        return _selectedEquipment.isNotEmpty;
      case 3: // Frequency
        return true;
      case 4: // Height/Weight (optional)
        return true;
      case 5: // Age/Gender (optional)
        return true;
      case 6: // Location
        return _selectedLocation != null;
      case 7: // Final Notes (optional)
        return true;
      default:
        return false;
    }
  }

  String _getPageTitle() {
    switch (_currentPage) {
      case 0:
        return 'Obiettivo';
      case 1:
        return 'Livello';
      case 2:
        return 'Attrezzatura';
      case 3:
        return 'Frequenza';
      case 4:
        return 'Dati Fisici';
      case 5:
        return 'Dettagli';
      case 6:
        return 'Location';
      case 7:
        return 'Note Finali';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildGoalPage(),
                  _buildLevelPage(),
                  _buildEquipmentPage(),
                  _buildFrequencyPage(),
                  _buildHeightWeightPage(),
                  _buildAgeGenderPage(),
                  _buildLocationPage(),
                  _buildFinalNotesPage(),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.borderSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: CleanTheme.textPrimary,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          const Spacer(),
          Column(
            children: [
              Text(
                _getPageTitle(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_currentPage + 1}/$_totalPages',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Skip button for optional pages
          if (_currentPage >= 4 && _currentPage <= 5)
            GestureDetector(
              onTap: _nextPage,
              child: Text(
                AppLocalizations.of(context)!.skipButton,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / _totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: CleanTheme.borderSecondary,
          valueColor: const AlwaysStoppedAnimation<Color>(
            CleanTheme.primaryColor,
          ),
          minHeight: 6,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 1: GOAL
  // ══════════════════════════════════════════════════════════
  Widget _buildGoalPage() {
    return _buildQuestionPage(
      emoji: '🎯',
      question: 'Qual è il tuo obiettivo principale?',
      subtitle: 'Scegli quello che ti rappresenta di più',
      child: Column(
        children: [
          _buildGoalOption(
            FitnessGoal.weightLoss,
            '🔥',
            'Perdere Peso',
            'Bruciare grassi e dimagrire',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.muscleGain,
            '💪',
            'Aumentare Massa',
            'Costruire muscoli e forza',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.toning,
            '⚡',
            'Tonificare',
            'Definizione e resistenza',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.wellness,
            '✨',
            'Benessere Generale',
            'Salute e forma fisica',
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(
    FitnessGoal goal,
    String emoji,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedGoal == goal;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedGoal = goal);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 2: LEVEL
  // ══════════════════════════════════════════════════════════
  Widget _buildLevelPage() {
    return _buildQuestionPage(
      emoji: '📊',
      question: 'Qual è il tuo livello?',
      subtitle: 'Non preoccuparti, adatteremo tutto a te',
      child: Column(
        children: [
          _buildLevelOption(
            ExperienceLevel.beginner,
            '🌱',
            'Principiante',
            'Nuovo al fitness o ripresa dopo pausa',
          ),
          const SizedBox(height: 12),
          _buildLevelOption(
            ExperienceLevel.intermediate,
            '🌿',
            'Intermedio',
            '6+ mesi di allenamento costante',
          ),
          const SizedBox(height: 12),
          _buildLevelOption(
            ExperienceLevel.advanced,
            '🌳',
            'Avanzato',
            '2+ anni di esperienza seria',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(
    ExperienceLevel level,
    String emoji,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedLevel = level);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 3: EQUIPMENT
  // ══════════════════════════════════════════════════════════
  Widget _buildEquipmentPage() {
    final equipment = [
      ('🏋️', 'Palestra Completa'),
      ('🏠', 'Casa con Attrezzi'),
      ('🤸', 'Solo Corpo Libero'),
      ('🎒', 'Manubri'),
      ('🔩', 'Bilanciere'),
      ('🧘', 'Elastici'),
    ];

    return _buildQuestionPage(
      emoji: '🏋️',
      question: 'Cosa hai a disposizione?',
      subtitle: 'Seleziona tutto ciò che puoi usare',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: equipment.map((eq) {
          final isSelected = _selectedEquipment.contains(eq.$2);
          return GestureDetector(
            onTap: () {
              HapticService.lightTap();
              setState(() {
                if (isSelected) {
                  _selectedEquipment.remove(eq.$2);
                } else {
                  _selectedEquipment.add(eq.$2);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                    : CleanTheme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? CleanTheme.primaryColor
                      : CleanTheme.borderPrimary,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(eq.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    eq.$2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 4: FREQUENCY
  // ══════════════════════════════════════════════════════════
  Widget _buildFrequencyPage() {
    return _buildQuestionPage(
      emoji: '📅',
      question: 'Quante volte a settimana?',
      subtitle: 'Puoi sempre cambiarlo dopo',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFrequencyButton(Icons.remove, () {
                if (_weeklyFrequency > 1) setState(() => _weeklyFrequency--);
              }),
              Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      '$_weeklyFrequency',
                      style: GoogleFonts.outfit(
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                    Text(
                      _weeklyFrequency == 1 ? 'giorno' : 'giorni',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildFrequencyButton(Icons.add, () {
                if (_weeklyFrequency < 7) setState(() => _weeklyFrequency++);
              }),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.borderSecondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: CleanTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFrequencyTip(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
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

  Widget _buildFrequencyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: Icon(icon, color: CleanTheme.textPrimary, size: 28),
      ),
    );
  }

  String _getFrequencyTip() {
    if (_weeklyFrequency <= 2) {
      return 'Perfetto per iniziare! Qualità > quantità.';
    } else if (_weeklyFrequency <= 4) {
      return 'Ottimo equilibrio tra allenamento e recupero!';
    } else {
      return 'Grande impegno! Assicurati di riposare adeguatamente.';
    }
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 5: HEIGHT & WEIGHT (Optional)
  // ══════════════════════════════════════════════════════════
  Widget _buildHeightWeightPage() {
    return _buildQuestionPage(
      emoji: '📏',
      question: 'Altezza e Peso',
      subtitle: 'Opzionale - aiuta a calcolare il volume ideale',
      isOptional: true,
      child: Column(
        children: [
          Row(
            children: [
              // Height
              Expanded(
                child: _buildNumericInput(
                  controller: _heightController,
                  label: 'Altezza',
                  suffix: 'cm',
                  hint: '175',
                ),
              ),
              const SizedBox(width: 16),
              // Weight
              Expanded(
                child: _buildNumericInput(
                  controller: _weightController,
                  label: 'Peso',
                  suffix: 'kg',
                  hint: '70',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CleanTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Questi dati permettono di personalizzare meglio la scheda',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
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

  Widget _buildNumericInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CleanTheme.borderPrimary),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textTertiary,
              ),
              suffixText: suffix,
              suffixStyle: GoogleFonts.inter(
                fontSize: 16,
                color: CleanTheme.textSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 6: AGE & GENDER (Optional)
  // ══════════════════════════════════════════════════════════
  Widget _buildAgeGenderPage() {
    return _buildQuestionPage(
      emoji: '👤',
      question: 'Età e Genere',
      subtitle: 'Opzionale - ottimizza il recupero',
      isOptional: true,
      child: Column(
        children: [
          // Age input
          _buildNumericInput(
            controller: _ageController,
            label: 'Età',
            suffix: 'anni',
            hint: '30',
          ),
          const SizedBox(height: 24),

          // Gender selection
          Text(
            'Genere',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenderOption(Gender.male, '👨', 'Uomo')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderOption(Gender.female, '👩', 'Donna')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(Gender gender, String emoji, String label) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedGender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? CleanTheme.primaryColor
                    : CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 7: LOCATION
  // ══════════════════════════════════════════════════════════
  Widget _buildLocationPage() {
    return _buildQuestionPage(
      emoji: '📍',
      question: 'Dove ti allenerai?',
      subtitle: 'Scegli il tuo ambiente principale',
      child: Column(
        children: [
          _buildLocationOption(
            TrainingLocation.gym,
            '🏢',
            'Palestra',
            'Accesso a tutti i macchinari',
          ),
          const SizedBox(height: 12),
          _buildLocationOption(
            TrainingLocation.home,
            '🏠',
            'Casa',
            'Allenamento domestico',
          ),
          const SizedBox(height: 12),
          _buildLocationOption(
            TrainingLocation.outdoor,
            '🌳',
            'All\'aperto',
            'Parchi e aree esterne',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(
    TrainingLocation location,
    String emoji,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedLocation == location;
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() => _selectedLocation = location);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 8: FINAL NOTES
  // ══════════════════════════════════════════════════════════
  Widget _buildFinalNotesPage() {
    return _buildQuestionPage(
      emoji: '✍️',
      question: 'Ultimi Dettagli',
      subtitle: 'C\'è qualcos\'altro da sapere?',
      isOptional: true,
      child: Column(
        children: [
          // Name field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Come ti chiami?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: CleanTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CleanTheme.borderPrimary),
                ),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Il tuo nome',
                    hintStyle: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notes field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note aggiuntive (opzionale)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: CleanTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: CleanTheme.borderPrimary),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: CleanTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Es: infortuni, preferenze, obiettivi specifici...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 15,
                      color: CleanTheme.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ══════════════════════════════════════════════════════════
  Widget _buildQuestionPage({
    required String emoji,
    required String question,
    required String subtitle,
    required Widget child,
    bool isOptional = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  question,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOptional)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'OPZIONALE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: CleanTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isLastPage = _currentPage == _totalPages - 1;
    final buttonText = isLastPage
        ? (_isSaving ? 'Salvataggio...' : 'Completa Profilo')
        : 'Continua';

    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _canProceed() && !_isSaving ? _nextPage : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _canProceed() && !_isSaving
                ? CleanTheme.primaryColor
                : CleanTheme.borderSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _canProceed()
                          ? Colors.white
                          : CleanTheme.textTertiary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
