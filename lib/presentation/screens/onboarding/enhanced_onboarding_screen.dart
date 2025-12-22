import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/clean_widgets.dart';
import '../questionnaire/unified_questionnaire_screen.dart';

class EnhancedOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const EnhancedOnboardingScreen({super.key, this.onComplete});

  @override
  State<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState extends State<EnhancedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Optimized for conversion: Focus on unique value proposition (real-time voice coaching)
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imagePath: 'assets/images/gigi_trainer.png',
      title: 'Ciao, sono GIGI!',
      description:
          'Il tuo Personal Trainer AI. Ti seguo a voce durante ogni esercizio e correggo la tua tecnica in tempo reale.',
      highlightText: 'Come avere un coach sempre con te.',
      icon: Icons.mic,
      accentColor: CleanTheme.primaryColor,
    ),
    OnboardingPageData(
      imagePath: 'assets/images/gigi_new_logo.png',
      title: 'Coaching Vocale Live',
      description:
          'Ti guido a voce durante ogni esercizio. Ti dico cosa fare, quando farlo, come farlo.',
      highlightText: 'Nessun\'altra app al mondo fa questo.',
      icon: Icons.record_voice_over,
      accentColor: CleanTheme.accentBlue,
    ),
    OnboardingPageData(
      title: 'Inizia Ora',
      description:
          'Il tuo primo allenamento guidato è pronto. Metti le cuffie e iniziamo.',
      highlightText: '🎧 Esperienza migliore con auricolari',
      icon: Icons.headphones,
      accentColor: CleanTheme.primaryColor,
      isLast: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with progress
            _buildTopBar(),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  HapticService.lightTap();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final progress = (_currentPage + 1) / _pages.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'completato',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: CleanTheme.borderSecondary,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _pages[_currentPage].accentColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Skip button
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipToEnd,
              child: Text(
                'Salta',
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image/Icon container - larger for impact
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: page.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: page.imagePath != null
                ? ClipOval(
                    child: Image.asset(
                      page.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(page.icon, size: 80, color: page.accentColor),
                    ),
                  )
                : Icon(page.icon, size: 80, color: page.accentColor),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CleanTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Highlight text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: page.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: page.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: page.accentColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    page.highlightText,
                    style: GoogleFonts.inter(
                      color: page.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicator
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: page.accentColor,
              dotColor: CleanTheme.borderPrimary,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              spacing: 8,
            ),
          ),

          const SizedBox(height: 32),

          // CTA Button - Optimized for conversion
          CleanButton(
            text: isLast ? 'Avvia Allenamento Guidato' : 'Continua',
            trailingIcon: isLast
                ? Icons.play_arrow_rounded
                : Icons.arrow_forward,
            backgroundColor: page.accentColor,
            textColor: Colors.white,
            width: double.infinity,
            onPressed: isLast ? _getStarted : _nextPage,
          ),

          // Social proof
          if (_currentPage == 0) ...[
            const SizedBox(height: 16),
            Text(
              '🎉 12,847 persone hanno iniziato questo mese',
              style: GoogleFonts.inter(
                color: CleanTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    HapticService.mediumTap();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToEnd() {
    HapticService.lightTap();
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _getStarted() {
    HapticService.celebrationPattern();
    // Navigate directly to the questionnaire ("Parlaci di te")
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const UnifiedQuestionnaireScreen()),
    );
  }
}

class OnboardingPageData {
  final IconData icon;
  final String? imagePath;
  final String title;
  final String description;
  final String highlightText;
  final Color accentColor;
  final bool isLast;

  OnboardingPageData({
    required this.icon,
    this.imagePath,
    required this.title,
    required this.description,
    required this.highlightText,
    required this.accentColor,
    this.isLast = false,
  });
}
