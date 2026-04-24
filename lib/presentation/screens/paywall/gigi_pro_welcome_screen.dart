import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class GigiProWelcomeScreen extends StatefulWidget {
  const GigiProWelcomeScreen({super.key});

  @override
  State<GigiProWelcomeScreen> createState() => _GigiProWelcomeScreenState();
}

class _GigiProWelcomeScreenState extends State<GigiProWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _appearanceController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _confettiController.play();
        _appearanceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // --- HERO ICON ---
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  CleanTheme.accentGold,
                                  Color(0xFFC5A059),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CleanTheme.accentGold.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- TITLE & SUBTITLE ---
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _appearanceController,
                      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'GIGI Pro è attivo.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: CleanTheme.textPrimary,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'La tua evoluzione ha inizio oggi. Hai sbloccato il massimo potenziale del tuo coach AI per un\'esperienza d\'élite.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: CleanTheme.textSecondary,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- BENEFITS GRID ---
                  _AnimatedBenefit(
                    index: 0,
                    controller: _appearanceController,
                    icon: Icons.graphic_eq_rounded,
                    title: 'Feedback Tecnico Realtime',
                    subtitle:
                        'Guida vocale istantanea per perfezionare ogni singola ripetizione.',
                  ),
                  _AnimatedBenefit(
                    index: 1,
                    controller: _appearanceController,
                    icon: Icons.bolt_rounded,
                    title: 'Programmazione Adattiva',
                    subtitle:
                        'Piani che imparano dalle tue performance e si evolvono in tempo reale.',
                  ),
                  _AnimatedBenefit(
                    index: 2,
                    controller: _appearanceController,
                    icon: Icons.layers_outlined,
                    title: 'Ecosistema Intelligente',
                    subtitle:
                        'Analisi avanzata e strumenti nutrizionali prioritari per il tuo obiettivo.',
                  ),

                  const Spacer(flex: 3),

                  // --- SINGLE ACTION BUTTON ---
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _appearanceController,
                      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
                    ),
                    child: CleanButton(
                      text: 'Inizia il percorso',
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          _buildConfettiLayer(Alignment.topCenter, math.pi / 2),
        ],
      ),
    );
  }

  Widget _buildConfettiLayer(Alignment alignment, double blastDirection) {
    return Align(
      alignment: alignment,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirectionality: BlastDirectionality.directional,
        blastDirection: blastDirection,
        emissionFrequency: 0.04,
        numberOfParticles: 20,
        maxBlastForce: 15,
        minBlastForce: 5,
        gravity: 0.25,
        shouldLoop: false,
        colors: const [
          CleanTheme.accentGold,
          Color(0xFFC5A059),
          Color(0xFFE5E5EA),
          Colors.black,
        ],
      ),
    );
  }
}

class _AnimatedBenefit extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final IconData icon;
  final String title;
  final String subtitle;

  const _AnimatedBenefit({
    required this.index,
    required this.controller,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final start = 0.3 + (index * 0.1);
    final end = start + 0.4;

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
        child: CleanCard(
          enableGlass: true,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: CleanTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

