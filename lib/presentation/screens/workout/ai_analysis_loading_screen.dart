import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/liquid_steel_container.dart';

class AiAnalysisLoadingScreen extends StatefulWidget {
  final Future<void> Function() onGenerate;

  const AiAnalysisLoadingScreen({super.key, required this.onGenerate});

  @override
  State<AiAnalysisLoadingScreen> createState() =>
      _AiAnalysisLoadingScreenState();
}

class _AiAnalysisLoadingScreenState extends State<AiAnalysisLoadingScreen> {
  final List<String> _steps = [
    "Scansione dello storico carichi...",
    "Analisi dei pattern di fatica neurale...",
    "Ottimizzazione del volume per macrociclo...",
    "Calibrazione del Progressive Overload...",
    "Finalizzazione della scheda personalizzata...",
  ];
  int _currentStep = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSteps();
    _executeGeneration();
  }

  void _startSteps() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _executeGeneration() async {
    await widget.onGenerate();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rotating Steel Icon
              LiquidSteelContainer(
                borderRadius: 40,
                enableShine: true,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Animated Text
              Text(
                "GIGI AI ANALYSIS",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.primaryColor,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 20),

              // Progress Message
              SizedBox(
                height: 30,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _steps[_currentStep],
                    key: ValueKey<int>(_currentStep),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Professional Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: CleanTheme.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CleanTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 60),
              Text(
                "Stiamo calcolando l'incremento di carico scientificamente perfetto per te.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
