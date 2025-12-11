import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/form_analysis_model.dart';
import '../../../data/services/form_analysis_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
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
  XFile? _videoFile;
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
        // Use XFile.length() which works on Web too
        final fileSize = await pickedFile.length();

        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video troppo grande! Max 50MB'),
                backgroundColor: CleanTheme.accentRed,
              ),
            );
          }
          return;
        }

        setState(() => _videoFile = pickedFile);
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
          content: Text('Seleziona video e inserisci nome esercizio'),
        ),
      );
      return;
    }

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
        videoFile: _videoFile!,
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
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: CleanTheme.accentRed,
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
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Limite Raggiunto',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Hai raggiunto il limite giornaliero di ${_quota?.dailyLimit ?? 3} analisi.\n\nUpgrade a Premium per analisi illimitate!',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Chiudi',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          CleanButton(
            text: 'Upgrade',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'AI Form Check',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                    CleanButton(
                      text: 'Analizza Esecuzione',
                      icon: Icons.auto_awesome,
                      width: double.infinity,
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

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPremium
                  ? CleanTheme.accentOrange.withValues(alpha: 0.1)
                  : CleanTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium : Icons.analytics_outlined,
              color: isPremium
                  ? CleanTheme.accentOrange
                  : CleanTheme.accentBlue,
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
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'Analisi illimitate'
                      : '$remaining/${_quota!.dailyLimit} rimaste oggi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: remaining > 0 || isPremium
                        ? CleanTheme.accentGreen
                        : CleanTheme.accentRed,
                    fontWeight: FontWeight.w600,
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
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Nome Esercizio',
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        hintText: 'es. Squat, Panca piana, Stacco...',
        hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
        prefixIcon: const Icon(
          Icons.fitness_center_outlined,
          color: CleanTheme.textSecondary,
        ),
        filled: true,
        fillColor: CleanTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CleanTheme.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return Column(
      children: [
        CleanCard(
          onTap: () => _pickVideo(ImageSource.camera),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 40,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Registra Video',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max 15 secondi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CleanCard(
          onTap: () => _pickVideo(ImageSource.gallery),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: CleanTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Carica dalla Galleria',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: CleanTheme.borderSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: CleanTheme.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: CleanTheme.accentGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Video selezionato',
                    style: GoogleFonts.inter(
                      color: CleanTheme.accentGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => _videoFile = null),
                icon: const Icon(
                  Icons.delete_outline,
                  color: CleanTheme.accentRed,
                  size: 20,
                ),
                label: Text(
                  'Rimuovi',
                  style: GoogleFonts.inter(color: CleanTheme.accentRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingWidget() {
    return CleanCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(color: CleanTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            _uploadProgress < 1.0
                ? 'Caricamento... ${(_uploadProgress * 100).toInt()}%'
                : 'Gemini sta analizzando...',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadProgress < 1.0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: CleanTheme.borderSecondary,
                color: CleanTheme.primaryColor,
                minHeight: 6,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Questo può richiedere 30-60 secondi',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
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
                  Icons.info_outline,
                  color: CleanTheme.accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Come funziona',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
