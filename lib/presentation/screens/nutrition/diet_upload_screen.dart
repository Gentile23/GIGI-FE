import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/nutrition_coach_provider.dart';
import '../../../../core/theme/clean_theme.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../data/services/quota_service.dart';
import '../../widgets/animations/liquid_steel_container.dart';

class DietUploadScreen extends StatefulWidget {
  const DietUploadScreen({super.key});

  @override
  State<DietUploadScreen> createState() => _DietUploadScreenState();
}

class _DietUploadScreenState extends State<DietUploadScreen> {
  // Logic migrated to Provider
  String _loadingMessage = 'Caricamento...';

  void _startLoadingMessages() {
    _updateMessage([
      'Analisi del PDF in corso...',
      'Lettura degli alimenti...',
      'Calcolo dei macronutrienti...',
      'Quasi fatto...',
    ]);
  }

  Future<void> _updateMessage(List<String> messages) async {
    for (final msg in messages) {
      if (!mounted) return;
      setState(() => _loadingMessage = msg);
      await Future.delayed(const Duration(seconds: 4));
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final provider = Provider.of<NutritionCoachProvider>(
        context,
        listen: false,
      );
      if (provider.isLoading) return;

      final quotaService = QuotaService();
      final quotaCheck = await quotaService.canPerformAction(
        QuotaAction.pdfDiet,
      );
      if (!quotaCheck.canPerform) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              quotaCheck.reason.isNotEmpty
                  ? quotaCheck.reason
                  : 'Hai raggiunto il limite di analisi PDF dieta.',
            ),
            backgroundColor: CleanTheme.accentOrange,
          ),
        );
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = result.files.single;
        final fileName = file.name.trim();
        if (fileName.isEmpty ||
            fileName.length > 120 ||
            !(file.extension?.toLowerCase() == 'pdf')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seleziona un PDF valido.'),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
          return;
        }
        if (file.size <= 0 || file.size > ValidationUtils.maxPdfUploadBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Il PDF deve essere piu piccolo di 10MB.'),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
          return;
        }

        if (!mounted) return;

        _startLoadingMessages();

        final success = await provider.uploadDiet(file);

        if (success) {
          if (mounted) {
            // Success! The provider now holds the active plan.
            Navigator.of(context).pushReplacementNamed('/nutrition/coach/plan');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Errore durante l\'upload della dieta'),
                backgroundColor: CleanTheme.accentRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Si è verificato un errore durante l\'upload'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for loading state
    final isLoading = context.select<NutritionCoachProvider, bool>(
      (p) => p.isLoading,
    );

    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Carica la tua Dieta',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CleanTheme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        titleTextStyle: const TextStyle(
          color: CleanTheme.textPrimary,
          fontSize: 20,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 64,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Importa la tua Dieta',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Carica il PDF della tua dieta fornito da un nutrizionista. GiGi analizzerà il documento e creerà il tuo piano digitale.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // 14-day limit info alert
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CleanTheme.accentGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: CleanTheme.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Supportiamo diete fino a 14 giorni (2 settimane).',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CleanTheme.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              if (isLoading)
                Column(
                  children: [
                    const SizedBox(
                      width: 100,
                      height: 100,
                      child: LiquidSteelContainer(
                        borderRadius: 50,
                        enableShine: true,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _loadingMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L\'AI di GiGi sta elaborando la tua dieta...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickAndUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Seleziona PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (!isLoading) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annulla',
                    style: GoogleFonts.inter(
                      color: CleanTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
