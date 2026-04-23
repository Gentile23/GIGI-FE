import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/form_analysis_model.dart';
import '../../../data/services/form_analysis_service.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/quota_service.dart';
import '../../../providers/quota_provider.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/clean_widgets.dart';
import 'form_analysis_result_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../widgets/quota/quota_banner.dart';
import '../../../core/constants/gigi_guidance_content.dart';

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
  late final QuotaService _quotaService;

  FormAnalysisQuota? _quota;
  XFile? _videoFile;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _quotaService = QuotaService();
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
    try {
      final status = await _quotaService.getQuotaStatus();
      if (mounted) {
        setState(() {
          _quota = FormAnalysisQuota.fromQuotaUsage(
            usage: status.usage.formAnalysis,
            isPremium: status.isPremium,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading form-analysis quota status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      if (_isAnalyzing) return;

      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );

      if (pickedFile != null) {
        // Use XFile.length() which works on Web too
        final fileSize = await pickedFile.length();

        if (fileSize > ValidationUtils.maxFormVideoBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.videoTooLarge),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Si è verificato un errore. Riprova.')),
        );
      }
    }
  }

  Future<void> _analyzeVideo() async {
    if (_isAnalyzing) return;
    if (_videoFile == null || _exerciseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectVideoAndExercise),
        ),
      );
      return;
    }

    final sanitizedExerciseName = ValidationUtils.sanitizeFreeText(
      _exerciseController.text,
      maxLength: ValidationUtils.maxAiLabelLength,
    );
    if (sanitizedExerciseName.isEmpty ||
        ValidationUtils.containsSuspiciousMarkup(sanitizedExerciseName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un nome esercizio valido.'),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
      return;
    }

    if (_quota != null && !_quota!.canAnalyze && !_quota!.isPremium) {
      _showUpgradeDialog();
      return;
    }

    final checkResult = await _quotaService.canPerformAction(
      QuotaAction.formAnalysis,
    );
    if (!checkResult.canPerform) {
      await _loadQuota();
      if (mounted) {
        _showUpgradeDialog(reason: checkResult.reason);
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _uploadProgress = 0.0;
    });

    try {
      final analysis = await _service.analyzeVideo(
        videoFile: _videoFile!,
        exerciseName: sanitizedExerciseName,
        exerciseId: widget.exerciseId,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (mounted && analysis != null) {
        await context.read<QuotaProvider>().syncAfterSuccess(
          QuotaAction.formAnalysis,
        );
        if (!mounted) return;

        // Use push instead of pushReplacement so we can go back to this screen
        // and perform another analysis
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormAnalysisResultScreen(analysis: analysis),
          ),
        );

        // Optional: Clear video after returning if desired, but for now just keeping state
        // setState(() => _videoFile = null);

        // Refresh quota after returning from result screen
        await _loadQuota();
      } else {
        if (!mounted) return;
        throw Exception(AppLocalizations.of(context)!.analysisFailed);
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        await _loadQuota();
        if (mounted) {
          _showUpgradeDialog(reason: _extractApiError(e));
        }
        return;
      }

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

  void _showUpgradeDialog({String? reason}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)!.limitReached,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          reason != null && reason.trim().isNotEmpty
              ? reason
              : _limitReachedMessage(),
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.close,
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          CleanButton(
            text: AppLocalizations.of(context)!.upgrade,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _limitReachedMessage() {
    final quota = _quota;
    if (quota == null) {
      return AppLocalizations.of(context)!.limitReachedDesc(1);
    }

    final periodLabel = _periodLabel(quota.period);
    final limit = quota.limit == -1 ? 0 : quota.limit;
    return 'Hai raggiunto il limite di $limit analisi $periodLabel.\n\nUpgrade a Premium per analisi illimitate!';
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'day':
        return 'oggi';
      case 'week':
        return 'questa settimana';
      case 'month':
        return 'questo mese';
      case 'lifetime':
        return 'in totale';
      default:
        return 'in questo periodo';
    }
  }

  String? _extractApiError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['error'] ?? data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      return null;
    }

    if (data is Map) {
      final mapped = Map<String, dynamic>.from(data);
      final message = mapped['error'] ?? mapped['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.aiFormCheck,
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
                  GigiCoachMessage(
                    messageId: 'form_analysis.upload_intro',
                    title: 'Prima dell analisi',
                    message: GigiGuidanceContent.formAnalysisIntro(),
                    emotion: GigiEmotion.expert,
                  ),
                  const SizedBox(height: 24),
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
                      text: AppLocalizations.of(context)!.analyzeForm,
                      icon: Icons.auto_awesome,
                      width: double.infinity,
                      onPressed: _analyzeVideo,
                    ),
                  if (_isAnalyzing) _buildAnalyzingWidget(),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuotaCard() {
    return QuotaBanner(
      action: QuotaAction.formAnalysis,
      onUpgrade: () {
        HapticService.lightTap();
        _showUpgradeDialog();
      },
    );
  }

  Widget _buildExerciseNameField() {
    return TextField(
      controller: _exerciseController,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.exerciseName,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        hintText: AppLocalizations.of(context)!.exerciseHint,
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
    return Row(
      children: [
        Expanded(
          child: CleanCard(
            width: double.infinity,
            onTap: () => _pickVideo(ImageSource.gallery),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 32,
                  color: CleanTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.uploadFromGallery,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: CleanTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CleanCard(
            width: double.infinity,
            onTap: () => _pickVideo(ImageSource.camera),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_outlined,
                  size: 32,
                  color: CleanTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.recordVideo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: CleanTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return CleanCard(
      width: double.infinity,
      padding: const EdgeInsets.all(0), // Removed padding for full bleed effect
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CleanTheme.primaryColor, CleanTheme.primaryLight],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Abstract pattern or overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          CleanTheme.primaryColor.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),

                // Play Button with Glassmorphism
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CleanTheme.textOnDark.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),

                // File Info Badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.movie_creation_outlined,
                              color: CleanTheme.textOnDark.withValues(
                                alpha: 0.7,
                              ),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _videoFile?.name ?? 'VIDEO',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: CleanTheme.textOnDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: CleanTheme.accentGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.videoSelected,
                            style: GoogleFonts.outfit(
                              color: CleanTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pronto per l\'analisi',
                        style: GoogleFonts.inter(
                          color: CleanTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove Button
                InkWell(
                  onTap: () => setState(() => _videoFile = null),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: CleanTheme.accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.remove,
                          style: GoogleFonts.inter(
                            color: CleanTheme.accentRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingWidget() {
    return CleanCard(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(color: CleanTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            _uploadProgress < 1.0
                ? AppLocalizations.of(
                    context,
                  )!.loadingProgress((_uploadProgress * 100).toInt())
                : AppLocalizations.of(context)!.analyzingForm,
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
            AppLocalizations.of(context)!.takeTimeDesc,
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
    return Column(
      children: [
        // How it works card
        CleanCard(
          width: double.infinity,
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
                    AppLocalizations.of(context)!.howItWorks,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                '📹',
                AppLocalizations.of(context)!.howItWorksStep1,
              ),
              _buildInfoItem(
                '🤖',
                AppLocalizations.of(context)!.howItWorksStep2,
              ),
              _buildInfoItem(
                '📊',
                AppLocalizations.of(context)!.howItWorksStep3,
              ),
              _buildInfoItem(
                '💡',
                AppLocalizations.of(context)!.howItWorksStep4,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Best practices card
        CleanCard(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_front_outlined,
                      color: CleanTheme.accentOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bestPracticesTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoItem('📱', AppLocalizations.of(context)!.bestPractice1),
              _buildInfoItem('🧘', AppLocalizations.of(context)!.bestPractice2),
              _buildInfoItem(
                '🧍‍♂️',
                AppLocalizations.of(context)!.bestPractice3,
              ),
              _buildInfoItem('⏱️', AppLocalizations.of(context)!.bestPractice4),
            ],
          ),
        ),
      ],
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
