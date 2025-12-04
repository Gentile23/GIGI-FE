import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/form_analysis_model.dart';
import '../../../data/services/form_analysis_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';
import 'form_analysis_result_screen.dart';

class FormAnalysisScreen extends StatefulWidget {
  final String? exerciseName;
  final int? exerciseId;

  const FormAnalysisScreen({super.key, this.exerciseName, this.exerciseId});

  @override
  State<FormAnalysisScreen> createState() => _FormAnalysisScreenState();
}

class _FormAnalysisScreenState extends State<FormAnalysisScreen> {
  final FormAnalysisService _service = FormAnalysisService(ApiClient());
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _exerciseController = TextEditingController();

  FormAnalysisQuota? _quota;
  File? _videoFile;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _exerciseController.text = widget.exerciseName ?? '';
    _loadQuota();
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  Future<void> _loadQuota() async {
    setState(() => _isLoading = true);
    final quota = await _service.checkQuota();
    if (mounted) {
      setState(() {
        _quota = quota;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // Check file size (max 50MB)
        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Video troppo grande! Max 50MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _videoFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  Future<void> _analyzeVideo() async {
    if (_videoFile == null || _exerciseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Seleziona video e inserisci nome esercizio'),
        ),
      );
      return;
    }

    // Check quota
    if (_quota != null && !_quota!.canAnalyze && !_quota!.isPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _uploadProgress = 0.0;
    });

    try {
      final analysis = await _service.analyzeVideo(
        videoPath: _videoFile!.path,
        exerciseName: _exerciseController.text,
        exerciseId: widget.exerciseId,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (mounted && analysis != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FormAnalysisResultScreen(analysis: analysis),
          ),
        );
      } else {
        throw Exception('Analisi fallita');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.cardColor,
        title: const Text('Limite Raggiunto'),
        content: Text(
          'Hai raggiunto il limite giornaliero di ${_quota?.dailyLimit ?? 3} analisi.\n\nUpgrade a Premium per analisi illimitate!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to premium upgrade screen
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Form Check',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ModernTheme.cardColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuotaCard(),
                  const SizedBox(height: 24),
                  _buildExerciseNameField(),
                  const SizedBox(height: 24),
                  if (_videoFile != null)
                    _buildVideoPreview()
                  else
                    _buildVideoSelector(),
                  const SizedBox(height: 32),
                  if (_videoFile != null && !_isAnalyzing)
                    ModernButton(
                      text: 'Analizza Esecuzione',
                      icon: Icons.psychology,
                      onPressed: _analyzeVideo,
                    ),
                  if (_isAnalyzing) _buildAnalyzingWidget(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuotaCard() {
    if (_quota == null) return const SizedBox.shrink();

    final remaining = _quota!.remaining;
    final isPremium = _quota!.isPremium;

    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPremium
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium : Icons.analytics,
              color: isPremium ? Colors.amber : Colors.blue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? '✨ Premium User' : 'Analisi Giornaliere',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'Analisi illimitate'
                      : '$remaining/${_quota!.dailyLimit} rimaste oggi',
                  style: TextStyle(
                    fontSize: 16,
                    color: remaining > 0 || isPremium
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseNameField() {
    return TextField(
      controller: _exerciseController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Nome Esercizio',
        hintText: 'es. Squat, Panca piana, Stacco...',
        prefixIcon: const Icon(Icons.fitness_center, color: Colors.white60),
        filled: true,
        fillColor: ModernTheme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ModernTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return Column(
      children: [
        ModernCard(
          onTap: () => _pickVideo(ImageSource.camera),
          child: Column(
            children: [
              Icon(Icons.videocam, size: 48, color: ModernTheme.primaryColor),
              const SizedBox(height: 12),
              Text(
                'Registra Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ModernTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Max 15 secondi',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ModernCard(
          onTap: () => _pickVideo(ImageSource.gallery),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, color: Colors.white70),
              const SizedBox(width: 8),
              const Text('Carica dalla Galleria'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return ModernCard(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '✅ Video selezionato',
                style: TextStyle(color: Colors.green),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _videoFile = null),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Rimuovi',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingWidget() {
    return ModernCard(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _uploadProgress < 1.0
                ? '📤 Caricamento... ${(_uploadProgress * 100).toInt()}%'
                : '🤖 Gemini sta analizzando...',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_uploadProgress < 1.0)
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white24,
              color: ModernTheme.primaryColor,
            ),
          const SizedBox(height: 8),
          const Text(
            'Questo può richiedere 30-60 secondi',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Come funziona',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem('📹', 'Registra o carica un video (max 15 sec)'),
          _buildInfoItem('🤖', 'Gemini AI analizza la tua esecuzione'),
          _buildInfoItem('📊', 'Ricevi feedback su postura ed errori'),
          _buildInfoItem('💡', 'Migliora con suggerimenti personalizzati'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
