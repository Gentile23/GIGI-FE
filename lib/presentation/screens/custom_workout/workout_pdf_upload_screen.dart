import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/custom_workout_service.dart';
import '../workout/unified_workout_list_screen.dart'; // Contains CustomWorkoutExecutionScreen
import '../../../data/models/custom_workout_model.dart';

class WorkoutPdfUploadScreen extends StatefulWidget {
  const WorkoutPdfUploadScreen({super.key});

  @override
  State<WorkoutPdfUploadScreen> createState() => _WorkoutPdfUploadScreenState();
}

class _WorkoutPdfUploadScreenState extends State<WorkoutPdfUploadScreen> {
  final CustomWorkoutService _service = CustomWorkoutService(ApiClient());

  bool _isLoading = false;
  String _loadingMessage = 'Caricamento...';

  void _startLoadingMessages() {
    _updateMessage([
      'Analisi del PDF in corso...',
      'Estrazione esercizi e serie...',
      'Calcolo tempi di recupero...',
      'Creazione scheda personalizzata...',
    ]);
  }

  Future<void> _updateMessage(List<String> messages) async {
    for (final msg in messages) {
      if (!mounted || !_isLoading) return;
      setState(() => _loadingMessage = msg);
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        if (!mounted) return;

        setState(() {
          _isLoading = true;
        });
        _startLoadingMessages();

        final response = await _service.uploadWorkoutPdf(result.files.single);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          final plan = response['plan'] as CustomWorkoutPlan;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Scheda creata con successo!'),
                backgroundColor: Color(0xFF00D26A),
              ),
            );

            final skippedExercises = List<String>.from(
              response['skipped_exercises'] ?? [],
            );

            if (skippedExercises.isNotEmpty) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('⚠️ Alcuni esercizi mancanti'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I seguenti esercizi non sono stati trovati nel database e sono stati saltati:',
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: skippedExercises.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        skippedExercises[index],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Potrai aggiungere esercizi alternativi modificando la scheda.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Navigate after closing dialog
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomWorkoutExecutionScreen(plan: plan),
                          ),
                        );
                      },
                      child: const Text('Ho capito'),
                    ),
                  ],
                ),
              );
            } else {
              // No skipped exercises, navigate directly
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => CustomWorkoutExecutionScreen(plan: plan),
                  ),
                );
              }
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? 'Errore durante il caricamento',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Carica Scheda PDF',
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
                  Icons.picture_as_pdf_rounded,
                  size: 64,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Importa la tua Scheda',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Carica il PDF fornito dal tuo trainer o creato da te. GiGi analizzerà il documento ed estrarrà automaticamente gli esercizi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              if (_isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      color: CleanTheme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _loadingMessage,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w500,
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

              if (!_isLoading) ...[
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
