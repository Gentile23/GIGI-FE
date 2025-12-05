import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_profile_model.dart';
import '../workout/trial_workout_generation_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// QUICK SETUP SCREEN - Streamlined onboarding with 5 questions
/// Psychology: Foot-in-the-door technique - small commitments first
/// Reduces friction, increases completion rate
/// ═══════════════════════════════════════════════════════════
class QuickSetupScreen extends StatefulWidget {
  const QuickSetupScreen({super.key});

  @override
  State<QuickSetupScreen> createState() => _QuickSetupScreenState();
}

class _QuickSetupScreenState extends State<QuickSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  // User selections
  FitnessGoal? _selectedGoal;
  ExperienceLevel? _selectedLevel;
  final Set<String> _selectedEquipment = {};
  int _weeklyFrequency = 3;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
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
    HapticService.mediumTap();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Save basic preferences
    await authProvider.updateUserProfile(
      name: _nameController.text.trim(),
      fitnessGoal: _selectedGoal,
      experienceLevel: _selectedLevel,
      preferredWorkoutDays: _weeklyFrequency,
      equipment: _selectedEquipment.toList(),
    );

    if (!mounted) return;

    // Navigate to trial workout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrialWorkoutGenerationScreen()),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null;
      case 1:
        return _selectedLevel != null;
      case 2:
        return _selectedEquipment.isNotEmpty;
      case 3:
        return true; // frequency always valid
      case 4:
        return _nameController.text.trim().isNotEmpty;
      default:
        return false;
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
                  _buildNamePage(),
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
          Text(
            '${_currentPage + 1}/$_totalPages',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textSecondary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_totalPages, (index) {
          final isCompleted = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalPages - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted
                    ? CleanTheme.primaryColor
                    : CleanTheme.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalPage() {
    return _buildQuestionPage(
      emoji: '🎯',
      question: 'Qual è il tuo obiettivo principale?',
      subtitle: 'Scegli quello che ti rappresenta di più',
      child: Column(
        children: [
          _buildGoalOption(
            FitnessGoal.loseWeight,
            '🔥',
            'Perdere Peso',
            'Bruciare grassi e dimagrire',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.buildMuscle,
            '💪',
            'Aumentare Massa',
            'Costruire muscoli e forza',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.improveEndurance,
            '⚡',
            'Migliorare Resistenza',
            'Più energia e stamina',
          ),
          const SizedBox(height: 12),
          _buildGoalOption(
            FitnessGoal.stayFit,
            '✨',
            'Mantenermi in Forma',
            'Benessere generale',
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
            'Nuovo al fitness',
          ),
          const SizedBox(height: 12),
          _buildLevelOption(
            ExperienceLevel.intermediate,
            '🌿',
            'Intermedio',
            'Qualche esperienza',
          ),
          const SizedBox(height: 12),
          _buildLevelOption(
            ExperienceLevel.advanced,
            '🌳',
            'Avanzato',
            'Esperto di allenamento',
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
      question: 'Dove ti alleni?',
      subtitle: 'Seleziona tutto ciò che hai a disposizione',
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

  Widget _buildNamePage() {
    return _buildQuestionPage(
      emoji: '👋',
      question: 'Come ti chiami?',
      subtitle: 'Il tuo coach AI userà questo nome',
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Il tuo nome',
              hintStyle: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textTertiary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          Container(
            height: 2,
            width: 200,
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage({
    required String emoji,
    required String question,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 24),
          Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _canProceed() ? _nextPage : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _canProceed()
                ? CleanTheme.primaryColor
                : CleanTheme.borderSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              _currentPage == _totalPages - 1
                  ? 'Inizia Trial Workout'
                  : 'Continua',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _canProceed() ? Colors.white : CleanTheme.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
