import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/form_analysis_model.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/gigi/gigi_coach_message.dart';

class FormAnalysisResultScreen extends StatelessWidget {
  final FormAnalysis analysis;

  const FormAnalysisResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Risultati Analisi',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGigiSummary(),
            const SizedBox(height: 16),
            _buildScoreCard(),
            const SizedBox(height: 16),
            if (analysis.summary != null) _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildStrengthsCard(),
            const SizedBox(height: 16),
            _buildWeaknessesCard(),
            const SizedBox(height: 16),
            if (analysis.detectedErrors.isNotEmpty) _buildErrorsCard(),
            const SizedBox(height: 16),
            if (analysis.suggestions.isNotEmpty) _buildSuggestionsCard(),
            const SizedBox(height: 16),
            _buildBodyAreasCard(),
            const SizedBox(height: 24),
            CleanButton(
              text: 'Nuova Analisi',
              icon: Icons.videocam_outlined,
              width: double.infinity,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final score = analysis.formScore ?? 0;
    final color = _getScoreColor(score);

    return CleanCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            analysis.exerciseName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '/10',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            analysis.scoreGrade,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.summarize_outlined,
                  color: CleanTheme.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Riepilogo',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis.summary!,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Card showing what's good about the form
  Widget _buildStrengthsCard() {
    // Extract strengths from feedback or generate from score
    final strengths = _extractStrengths();
    if (strengths.isEmpty) return const SizedBox.shrink();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: CleanTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '✅ Cosa va bene',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...strengths.map((s) => _buildCheckItem(s, CleanTheme.accentGreen)),
        ],
      ),
    );
  }

  /// Card showing what needs improvement
  Widget _buildWeaknessesCard() {
    // Extract weaknesses from errors or feedback
    final weaknesses = _extractWeaknesses();
    if (weaknesses.isEmpty) return const SizedBox.shrink();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: CleanTheme.accentRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '❌ Da migliorare',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...weaknesses.map((w) => _buildCheckItem(w, CleanTheme.accentRed)),
        ],
      ),
    );
  }

  /// Card showing body areas analysis
  Widget _buildBodyAreasCard() {
    final bodyAreas = _extractBodyAreas();
    if (bodyAreas.isEmpty) return const SizedBox.shrink();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: CleanTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🧑 Analisi per Zona',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bodyAreas.entries.map((e) => _buildBodyAreaItem(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            color == CleanTheme.accentGreen ? Icons.check : Icons.close,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyAreaItem(String area, String status) {
    final isGood =
        status.toLowerCase().contains('buon') ||
        status.toLowerCase().contains('corrett') ||
        status.toLowerCase().contains('ottim');
    final color = isGood ? CleanTheme.accentGreen : CleanTheme.accentOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGood ? Icons.check : Icons.build,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract strengths from feedback
  List<String> _extractStrengths() {
    final List<String> strengths = [];
    final feedback = analysis.feedback;
    final score = analysis.formScore ?? 0;

    // From feedback map
    if (feedback['strengths'] is List) {
      strengths.addAll((feedback['strengths'] as List).cast<String>());
    }
    if (feedback['positives'] is List) {
      strengths.addAll((feedback['positives'] as List).cast<String>());
    }

    // Generate based on score if no explicit strengths
    if (strengths.isEmpty && score >= 5) {
      if (score >= 8) {
        strengths.add('Ottima esecuzione complessiva');
        strengths.add('Controllo del movimento eccellente');
      } else if (score >= 6) {
        strengths.add('Buona stabilità generale');
      }
    }

    return strengths;
  }

  /// Extract weaknesses from errors/feedback
  List<String> _extractWeaknesses() {
    final List<String> weaknesses = [];
    final feedback = analysis.feedback;

    // From feedback map
    if (feedback['weaknesses'] is List) {
      weaknesses.addAll((feedback['weaknesses'] as List).cast<String>());
    }
    if (feedback['areas_to_improve'] is List) {
      weaknesses.addAll((feedback['areas_to_improve'] as List).cast<String>());
    }

    // From detected errors
    for (var error in analysis.detectedErrors) {
      if (!weaknesses.contains(error.issue)) {
        weaknesses.add(error.issue);
      }
    }

    return weaknesses;
  }

  /// Extract body area analysis from feedback
  Map<String, String> _extractBodyAreas() {
    final Map<String, String> areas = {};
    final feedback = analysis.feedback;

    // Standard body area keys
    final areaKeys = {
      'back': '🦾 Schiena',
      'spine': '🦾 Colonna',
      'hips': '🎯 Bacino',
      'core': '💪 Core/Addome',
      'shoulders': '🤜 Spalle',
      'head': '🙂 Testa/Collo',
      'legs': '🦵 Gambe',
      'arms': '💪 Braccia',
      'posture': '🧑 Postura',
    };

    if (feedback['body_areas'] is Map) {
      final bodyAreas = feedback['body_areas'] as Map;
      for (var entry in bodyAreas.entries) {
        final label = areaKeys[entry.key.toString()] ?? entry.key.toString();
        areas[label] = entry.value.toString();
      }
    }

    // Add from analysis if no specific areas
    if (areas.isEmpty && analysis.summary != null) {
      // Try to extract from summary
      if (analysis.summary!.toLowerCase().contains('schiena')) {
        areas['🦾 Schiena'] = 'Posizione analizzata';
      }
      if (analysis.summary!.toLowerCase().contains('bacino')) {
        areas['🎯 Bacino'] = 'Allineamento verificato';
      }
    }

    return areas;
  }

  Widget _buildErrorsCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: CleanTheme.accentRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Errori Rilevati',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysis.detectedErrors.map((error) => _buildErrorItem(error)),
        ],
      ),
    );
  }

  Widget _buildErrorItem(FormError error) {
    final color = _getSeverityColor(error.severity);
    final icon = _getSeverityIcon(error.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error.issue,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: CleanTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Suggerimenti',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysis.suggestions.map(
            (suggestion) => _buildSuggestionItem(suggestion),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(FormSuggestion suggestion) {
    final color = _getPriorityColor(suggestion.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.priority.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.improvement,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return CleanTheme.accentGreen;
    if (score >= 6) return CleanTheme.accentOrange;
    if (score >= 4) return const Color(0xFFFF6B00);
    return CleanTheme.accentRed;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return CleanTheme.accentRed;
      case 'medium':
        return CleanTheme.accentOrange;
      case 'low':
        return const Color(0xFFFFC107);
      default:
        return CleanTheme.textTertiary;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.error_outline;
      case 'medium':
        return Icons.warning_amber_outlined;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return CleanTheme.accentGreen;
      case 'medium':
        return CleanTheme.accentBlue;
      case 'low':
        return CleanTheme.textTertiary;
      default:
        return CleanTheme.textTertiary;
    }
  }

  Widget _buildGigiSummary() {
    final score = analysis.formScore ?? 0;
    String message = '';
    GigiEmotion emotion = GigiEmotion.happy;

    if (score >= 8) {
      message =
          'Esecuzione magistrale! La tua tecnica è eccellente. Continua così e focalizzati sul carico progressivo.';
      emotion = GigiEmotion.celebrating;
    } else if (score >= 6) {
      message =
          'Buona tecnica, ma c\'è margine di miglioramento. Ho trovato piccoli errori che se corretti ti permetteranno di caricare di più in sicurezza.';
      emotion = GigiEmotion.expert;
    } else {
      message =
          'Dobbiamo lavorare sulla tecnica! Ci sono errori importanti che potrebbero causare infortuni. Segui i miei suggerimenti qui sotto.';
      emotion = GigiEmotion.motivational;
    }

    return GigiCoachMessage(message: message, emotion: emotion);
  }
}
