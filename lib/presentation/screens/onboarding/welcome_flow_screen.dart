import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../questionnaire/unified_questionnaire_screen.dart';

/// Welcome Flow - Step-by-step onboarding for first-time users
/// Reduces cognitive load by showing one question at a time
class WelcomeFlowScreen extends StatefulWidget {
  const WelcomeFlowScreen({super.key});

  @override
  State<WelcomeFlowScreen> createState() => _WelcomeFlowScreenState();
}

class _WelcomeFlowScreenState extends State<WelcomeFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // User selections
  String? _selectedGoal;
  String? _selectedExperience;

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'muscle_gain',
      'icon': Icons.fitness_center,
      'label': 'Aumentare Massa',
      'emoji': '💪',
    },
    {
      'id': 'weight_loss',
      'icon': Icons.local_fire_department,
      'label': 'Perdere Peso',
      'emoji': '🔥',
    },
    {
      'id': 'toning',
      'icon': Icons.accessibility_new,
      'label': 'Tonificare',
      'emoji': '✨',
    },
    {'id': 'strength', 'icon': Icons.bolt, 'label': 'Più Forza', 'emoji': '⚡'},
    {'id': 'wellness', 'icon': Icons.spa, 'label': 'Benessere', 'emoji': '🧘'},
  ];

  final List<Map<String, dynamic>> _experiences = [
    {
      'id': 'beginner',
      'label': 'Principiante',
      'desc': 'Non mi alleno da tanto',
      'emoji': '🌱',
    },
    {
      'id': 'intermediate',
      'label': 'Intermedio',
      'desc': 'Mi alleno regolarmente',
      'emoji': '🌿',
    },
    {
      'id': 'advanced',
      'label': 'Avanzato',
      'desc': 'Mi alleno da anni',
      'emoji': '🌳',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWelcome() async {
    // Save user preferences (goal + experience level)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_selectedGoal != null && _selectedExperience != null) {
      await authProvider.updateProfile(
        goal: _selectedGoal,
        level: _selectedExperience,
      );
    }

    // Navigate to full questionnaire (which leads to BodyMeasurements -> TrialWorkout)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UnifiedQuestionnaireScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: _previousStep,
                      color: CleanTheme.textPrimary,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(child: _buildProgressIndicator()),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentStep = page),
                children: [
                  _buildWelcomeStep(),
                  _buildGoalStep(),
                  _buildExperienceStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        return Container(
          width: index == _currentStep ? 32 : 12,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gigi Avatar
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/gigi_trainer.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          Text(
            'Ciao! Sono Gigi 👋',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Sarò il tuo personal trainer AI.\nRispondi a 2 domande veloci così posso creare il piano perfetto per te.',
            style: GoogleFonts.inter(
              fontSize: 17,
              height: 1.5,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          CleanButton(
            text: 'INIZIAMO!',
            onPressed: _nextStep,
            width: double.infinity,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            'Qual è il tuo obiettivo principale?',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Scegli quello più importante per te',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final isSelected = _selectedGoal == goal['id'];
                return _buildSelectionCard(
                  emoji: goal['emoji'],
                  icon: goal['icon'],
                  label: goal['label'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedGoal = goal['id']);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          CleanButton(
            text: 'AVANTI',
            onPressed: _selectedGoal != null ? _nextStep : null,
            width: double.infinity,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExperienceStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Text(
            'Qual è il tuo livello?',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Così calibro gli esercizi giusti per te',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          Expanded(
            child: ListView.separated(
              itemCount: _experiences.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final exp = _experiences[index];
                final isSelected = _selectedExperience == exp['id'];
                return _buildSelectionCard(
                  emoji: exp['emoji'],
                  label: exp['label'],
                  subtitle: exp['desc'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedExperience = exp['id']);
                  },
                  large: true,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          CleanButton(
            text: 'INIZIA IL TRIAL WORKOUT 🚀',
            onPressed: _selectedExperience != null ? _completeWelcome : null,
            width: double.infinity,
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              '3 esercizi per calibrare il tuo livello',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String emoji,
    IconData? icon,
    required String label,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool large = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(large ? 20 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.surfaceColor,
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
            Text(emoji, style: TextStyle(fontSize: large ? 36 : 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: large ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
