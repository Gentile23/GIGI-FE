import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/images/gigi_new_logo.png',
      title: 'Benvenuto in GIGI',
      description:
          'Il tuo coach fitness AI personale. Ottieni piani di allenamento personalizzati in base ai tuoi obiettivi e livello.',
    ),
    OnboardingPage(
      icon: Icons.assessment_outlined,
      title: '3 Workout di Valutazione',
      description:
          'Completa 3 allenamenti di valutazione così la nostra AI può capire il tuo livello attuale e creare il piano perfetto per te.',
    ),
    OnboardingPage(
      icon: Icons.mic_outlined,
      title: 'Voice Coaching',
      description:
          'Segui il coaching vocale AI durante i tuoi allenamenti e ricevi feedback in tempo reale sulla tua forma.',
    ),
    OnboardingPage(
      icon: Icons.workspace_premium_outlined,
      title: 'Scegli il Tuo Piano',
      description:
          'Inizia gratis o passa a Premium per sbloccare il coaching vocale AI, il rilevamento della postura e analytics avanzati.',
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
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipToEnd,
                  child: Text(
                    'Salta',
                    style: GoogleFonts.inter(
                      color: CleanTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  activeDotColor: CleanTheme.primaryColor,
                  dotColor: CleanTheme.borderSecondary,
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 12,
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: CleanButton(
                text: _currentPage == _pages.length - 1 ? 'Inizia' : 'Avanti',
                width: double.infinity,
                onPressed: _currentPage == _pages.length - 1
                    ? _getStarted
                    : _nextPage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.imagePath == null ? CleanTheme.primaryLight : null,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: page.imagePath != null
                ? ClipOval(
                    child: Image.asset(page.imagePath!, fit: BoxFit.cover),
                  )
                : Icon(page.icon, size: 64, color: CleanTheme.primaryColor),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.6,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }
}

class OnboardingPage {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String description;

  OnboardingPage({
    this.icon,
    this.imagePath,
    required this.title,
    required this.description,
  }) : assert(icon != null || imagePath != null);
}
