import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/modern_theme.dart';
import '../screens/form_analysis/form_analysis_screen.dart';
import 'modern_widgets.dart';

class FormCheckWidget extends StatelessWidget {
  const FormCheckWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FormAnalysisScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.pink.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, color: Colors.purple, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Form Check',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Analizza la tua esecuzione con Gemini AI',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        ],
      ),
    );
  }
}
