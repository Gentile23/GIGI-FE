import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../../providers/nutrition_coach_provider.dart';

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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        if (!mounted) return;

        final provider = Provider.of<NutritionCoachProvider>(
          context,
          listen: false,
        );
        _startLoadingMessages();

        final success = await provider.uploadDiet(result.files.single);

        if (success) {
          if (mounted) {
            // Success! The provider now holds the active plan.
            // Navigate to Plan Screen (or back if we came from there? Logic usually involves replacing this screen)
            Navigator.of(context).pushReplacementNamed('/nutrition/coach/plan');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Upload failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
      appBar: AppBar(title: const Text('Carica la tua Dieta')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Carica il PDF della tua dieta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'L\'intelligenza artificiale analizzerà il file e creerà il tuo piano digitale.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_loadingMessage, style: const TextStyle(fontSize: 16)),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Seleziona PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
