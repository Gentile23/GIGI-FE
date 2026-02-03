import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

/// Screen celebrativo post-calibrazione che mostra la "magia" dell'AI
class CalibrationCompleteScreen extends StatefulWidget {
  /// Dati calibrazione dal backend
  final int setsAnalyzed;
  final double avgRpe;
  final int weightAdjustmentPercent;

  const CalibrationCompleteScreen({
    super.key,
    this.setsAnalyzed = 24,
    this.avgRpe = 7.2,
    this.weightAdjustmentPercent = 12,
  });

  @override
  State<CalibrationCompleteScreen> createState() =>
      _CalibrationCompleteScreenState();
}

class _CalibrationCompleteScreenState extends State<CalibrationCompleteScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late AnimationController _counterController;
  late Animation<double> _fadeAnimation;
  late Animation<int> _setsCounterAnimation;

  bool _showStats = false;

  @override
  void initState() {
    super.initState();

    // Confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Counter animation
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _setsCounterAnimation = IntTween(begin: 0, end: widget.setsAnalyzed)
        .animate(
          CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
        );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Delay before starting
    await Future.delayed(const Duration(milliseconds: 300));

    // Start confetti
    _confettiController.play();

    // Start fade in
    _fadeController.forward();

    // Delay then show counter
    await Future.delayed(const Duration(milliseconds: 600));
    _counterController.forward();

    // Show stats after counter
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _showStats = true);
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // AI Icon with glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF9B59B6,
                            ).withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      '🧠 Calibrazione Completata!',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Ho analizzato ogni tuo movimento per creare il TUO profilo unico',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Animated counter
                    AnimatedBuilder(
                      animation: _setsCounterAnimation,
                      builder: (context, _) {
                        return Column(
                          children: [
                            Text(
                              '${_setsCounterAnimation.value}',
                              style: GoogleFonts.outfit(
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF00D26A),
                              ),
                            ),
                            Text(
                              'SET ANALIZZATI',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white54,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Stats cards (animated)
                    AnimatedOpacity(
                      opacity: _showStats ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedSlide(
                        offset: _showStats ? Offset.zero : const Offset(0, 0.2),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'I tuoi prossimi workout sono ora calibrati:',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    '📊',
                                    '+${widget.weightAdjustmentPercent}%',
                                    'Pesi',
                                  ),
                                  _buildStatItem(
                                    '⏱️',
                                    '${widget.avgRpe}',
                                    'RPE Medio',
                                  ),
                                  _buildStatItem(
                                    '🎯',
                                    '100%',
                                    'Personalizzato',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      child: CleanButton(
                        text: '🚀 Vedi la Prossima Scheda',
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Color(0xFF9B59B6),
                Color(0xFF00D26A),
                Color(0xFFFFD700),
                Color(0xFF3498DB),
                Color(0xFFE91E63),
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF00D26A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
