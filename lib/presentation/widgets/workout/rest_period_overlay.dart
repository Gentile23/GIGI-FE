import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/models/workout_model.dart';

/// ═══════════════════════════════════════════════════════════
/// REST PERIOD OVERLAY - Immersive countdown between sets
/// Psychology: Anticipation builds engagement, countdown reduces perceived wait
/// ═══════════════════════════════════════════════════════════
class RestPeriodOverlay extends StatefulWidget {
  final int totalSeconds;
  final WorkoutExercise? nextExercise;
  final bool isNextExerciseDifferent;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const RestPeriodOverlay({
    super.key,
    required this.totalSeconds,
    required this.onComplete,
    this.nextExercise,
    this.isNextExerciseDifferent = false,
    this.onSkip,
  });

  @override
  State<RestPeriodOverlay> createState() => _RestPeriodOverlayState();
}

class _RestPeriodOverlayState extends State<RestPeriodOverlay>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _timer;
  int _secondsRemaining = 0;

  // Motivational quotes for rest periods
  final List<String> _quotes = [
    "Respira. Recupera. Ripeti. 💪",
    "Il dolore è temporaneo, i risultati durano. 🔥",
    "Ogni goccia di sudore è un passo avanti. 💧",
    "Stai costruendo la versione migliore di te. ⭐",
    "La disciplina batte il talento. 🏆",
    "Il tuo corpo può. Convinc la mente. 🧠",
    "Oggi è il giorno che fa la differenza. 📈",
  ];

  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.totalSeconds;
    _currentQuote = _quotes[math.Random().nextInt(_quotes.length)];

    // Countdown animation
    _countdownController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    )..forward();

    // Pulse animation for the timer ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _secondsRemaining--;
      });

      // Haptic feedback at key moments
      if (_secondsRemaining == 10 ||
          _secondsRemaining == 5 ||
          _secondsRemaining == 3 ||
          _secondsRemaining == 2 ||
          _secondsRemaining == 1) {
        HapticService.lightTap();
      }

      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        HapticService.heavyTap();
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return secs.toString();
  }

  Color get _timerColor {
    if (_secondsRemaining <= 5) return CleanTheme.accentRed;
    if (_secondsRemaining <= 10) return CleanTheme.accentOrange;
    return CleanTheme.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? _secondsRemaining / widget.totalSeconds
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0D0D1A), const Color(0xFF1A1A2E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Rest label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    color: CleanTheme.accentGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECUPERO',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Animated circular timer
            AnimatedBuilder(
              animation: Listenable.merge([
                _countdownController,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _secondsRemaining <= 5 ? _pulseAnimation.value : 1.0,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        // Progress ring
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _timerColor,
                            ),
                          ),
                        ),
                        // Timer text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: _secondsRemaining < 60 ? 72 : 56,
                                fontWeight: FontWeight.w700,
                                color: _timerColor,
                              ),
                            ),
                            Text(
                              'secondi',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const Spacer(flex: 1),

            // Motivational quote
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _currentQuote,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(flex: 1),

            // Next exercise preview
            if (widget.nextExercise != null && widget.isNextExerciseDifferent)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: CleanTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROSSIMO',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.4),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.nextExercise!.exercise.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(flex: 1),

            // Skip button
            if (widget.onSkip != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: GestureDetector(
                  onTap: () {
                    HapticService.mediumTap();
                    widget.onSkip?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.skip_next_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SALTA RIPOSO',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
