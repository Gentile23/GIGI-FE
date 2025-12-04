import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

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
      imagePath: 'assets/images/gigi_logo.png',
      title: 'Welcome to GIGI',
      description:
          'Your personal AI fitness coach. Get personalized workout plans tailored to your goals and fitness level.',
    ),
    OnboardingPage(
      icon: Icons.assessment,
      title: '3 Assessment Workouts',
      description:
          'Complete 3 evaluation workouts so our AI can understand your current fitness level and create the perfect plan for you.',
    ),
    OnboardingPage(
      icon: Icons.mic,
      title: 'Voice Coaching',
      description:
          'Follow along with AI voice coaching during your workouts and get real-time feedback on your form.',
    ),
    OnboardingPage(
      icon: Icons.workspace_premium,
      title: 'Choose Your Plan',
      description:
          'Start free or upgrade to unlock AI voice coaching, pose detection, and advanced analytics.',
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
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipToEnd,
                child: const Text('Skip'),
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
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.backgroundLight,
                  dotHeight: 12,
                  dotWidth: 12,
                  spacing: 16,
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                      ? _getStarted
                      : _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  ),
                ),
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: page.imagePath == null ? AppColors.neonGradient : null,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: page.imagePath != null
                ? ClipOval(
                    child: Image.asset(page.imagePath!, fit: BoxFit.cover),
                  )
                : Icon(page.icon, size: 60, color: AppColors.background),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
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
