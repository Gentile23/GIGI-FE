import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/nutrition_coach_service.dart';

class DietUploadScreen extends StatefulWidget {
  const DietUploadScreen({super.key});

  @override
  State<DietUploadScreen> createState() => _DietUploadScreenState();
}

class _DietUploadScreenState extends State<DietUploadScreen> {
  final NutritionCoachService _service = NutritionCoachService();
  bool _isLoading = false;
  String _loadingMessage = 'Caricamento...';
  String? _errorMessage;

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
      if (!mounted || !_isLoading) return;
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
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        _startLoadingMessages();

        final response = await _service.uploadDietPdf(result.files.single);

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/nutrition/coach/plan');
          }
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Upload failed';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (_isLoading)
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
