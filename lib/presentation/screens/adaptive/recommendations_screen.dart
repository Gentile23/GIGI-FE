import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/adaptive_training_model.dart';
import '../../../data/services/adaptive_training_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late final AdaptiveTrainingService _adaptiveService;
  List<TrainingRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adaptiveService = AdaptiveTrainingService(ApiClient());
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    final recommendations = await _adaptiveService.getRecommendations();

    if (mounted) {
      setState(() {
        _recommendations = recommendations ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _applyRecommendation(
    TrainingRecommendation recommendation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Applica Raccomandazione?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Questo modificherà il tuo piano in base a:\n\n${recommendation.reason}',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          CleanButton(
            text: 'Applica',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adaptiveService.applyRecommendation(
        recommendation.id,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Raccomandazione applicata!'),
              backgroundColor: CleanTheme.accentGreen,
            ),
          );
          _loadRecommendations();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'applicazione'),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _dismissRecommendation(
    TrainingRecommendation recommendation,
  ) async {
    final success = await _adaptiveService.dismissRecommendation(
      recommendation.id,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _recommendations.remove(recommendation);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Raccomandazione ignorata')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Raccomandazioni AI',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          CleanIconButton(
            icon: Icons.refresh_outlined,
            onTap: _loadRecommendations,
            hasBorder: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : _recommendations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              color: CleanTheme.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  return _buildRecommendationCard(_recommendations[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: CleanTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessuna Raccomandazione',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stai andando alla grande! Continua così.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(TrainingRecommendation recommendation) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: recommendation.typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  recommendation.typeIcon,
                  color: recommendation.typeColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.typeLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: recommendation.typeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 14,
                          color: CleanTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(recommendation.confidenceScore * 100).toInt()}% confidenza',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            recommendation.reason,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          if (recommendation.suggestedChanges != null &&
              recommendation.suggestedChanges!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.borderSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modifiche Suggerite:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recommendation.suggestedChanges!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: recommendation.typeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatKey(entry.key)}: ${entry.value}%',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CleanButton(
                  text: 'Ignora',
                  isOutlined: true,
                  onPressed: () => _dismissRecommendation(recommendation),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: CleanButton(
                  text: 'Applica',
                  icon: Icons.check,
                  onPressed: () => _applyRecommendation(recommendation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
