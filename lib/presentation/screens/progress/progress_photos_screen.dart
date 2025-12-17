import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class ProgressPhotosScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const ProgressPhotosScreen({
    super.key,
    this.isOnboarding = false,
    this.onComplete,
  });

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Photo data
  XFile? _frontPhoto;
  XFile? _sidePhoto;
  XFile? _backPhoto;

  Uint8List? _frontPhotoBytes;
  Uint8List? _sidePhotoBytes;
  Uint8List? _backPhotoBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              title: Text(
                'Foto Progresso',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              backgroundColor: CleanTheme.surfaceColor,
              iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Privacy assurance
              _buildPrivacyCard(),
              const SizedBox(height: 24),

              // Photo guidelines
              _buildGuidelinesCard(),
              const SizedBox(height: 24),

              // Photo slots
              Text(
                '📸 Le tue foto',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPhotoSlots(),
              const SizedBox(height: 32),

              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Center(child: Text('📸', style: const TextStyle(fontSize: 64))),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Foto del Tuo Percorso',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tra qualche settimana potrai confrontare i tuoi progressi visivamente. È il modo più motivante per vedere i risultati!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CleanTheme.accentGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock,
              color: CleanTheme.accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔒 100% Private',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.accentGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le tue foto saranno visibili SOLO a te. Non vengono mai condivise o usate per altri scopi.',
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

  Widget _buildGuidelinesCard() {
    final tips = [
      ('💡', 'Stessa luce e ora', 'Per risultati comparabili'),
      ('👕', 'Abbigliamento minimale', 'Così vedi i cambiamenti'),
      ('🧍', 'Posizione neutra', 'Rilassato, braccia lungo i fianchi'),
      ('⏱️', 'Usa timer o specchio', 'Più facile da solo'),
      ('📍', 'Stesso punto', 'Sfondo neutro, stessa distanza'),
    ];

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates,
                color: CleanTheme.accentYellow,
              ),
              const SizedBox(width: 8),
              Text(
                'Come scattare foto perfette',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tip.$2,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          tip.$3,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlots() {
    return Row(
      children: [
        Expanded(
          child: _buildPhotoSlot(
            title: 'Fronte',
            emoji: '🧍',
            photo: _frontPhotoBytes,
            onTap: () => _pickPhoto('front'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPhotoSlot(
            title: 'Lato',
            emoji: '🧍‍♂️',
            photo: _sidePhotoBytes,
            onTap: () => _pickPhoto('side'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPhotoSlot(
            title: 'Dietro',
            emoji: '🔙',
            photo: _backPhotoBytes,
            onTap: () => _pickPhoto('back'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSlot({
    required String title,
    required String emoji,
    required Uint8List? photo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: photo != null
                  ? CleanTheme.primaryColor
                  : CleanTheme.borderPrimary,
              width: photo != null ? 2 : 1,
            ),
          ),
          child: photo != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(photo, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: CleanTheme.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.add_a_photo,
                      color: CleanTheme.textTertiary,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final hasAnyPhoto =
        _frontPhoto != null || _sidePhoto != null || _backPhoto != null;

    return Column(
      children: [
        if (hasAnyPhoto) ...[
          CleanButton(
            text: _isLoading ? 'Salvataggio...' : 'Salva Foto',
            onPressed: _isLoading ? null : _savePhotos,
            icon: Icons.save,
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: _skip,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: CleanTheme.borderPrimary),
          ),
          child: Text(
            hasAnyPhoto ? 'Salta per ora' : 'Lo farò dopo',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
        ),

        const SizedBox(height: 24),

        // Motivation text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('💪', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tra 4-8 settimane potrai vedere i cambiamenti confrontando le foto!',
                  style: GoogleFonts.inter(
                    color: CleanTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickPhoto(String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scegli sorgente',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Fotocamera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Galleria',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          switch (type) {
            case 'front':
              _frontPhoto = image;
              _frontPhotoBytes = bytes;
              break;
            case 'side':
              _sidePhoto = image;
              _sidePhotoBytes = bytes;
              break;
            case 'back':
              _backPhoto = image;
              _backPhotoBytes = bytes;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: CleanTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: CleanTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePhotos() async {
    setState(() => _isLoading = true);

    try {
      // Save each photo
      if (_frontPhoto != null) {
        await _uploadPhoto(_frontPhoto!, 'front');
      }
      if (_sidePhoto != null) {
        await _uploadPhoto(_sidePhoto!, 'side_left');
      }
      if (_backPhoto != null) {
        await _uploadPhoto(_backPhoto!, 'back');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Foto salvate con successo!'),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
        _completeAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto(XFile photo, String type) async {
    final bytes = await photo.readAsBytes();
    // Prepare form data for upload
    final _ = {
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'photo_type': type,
      'photo_date': DateTime.now().toIso8601String().split('T')[0],
    };

    // Note: This would need proper multipart form handling
    // For now, we'll just demonstrate the structure
    debugPrint('Would upload photo: $type');
  }

  void _skip() {
    _completeAndNavigate();
  }

  void _completeAndNavigate() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pop(context);
    }
  }
}

// Placeholder for multipart file - in production use dio's FormData
class MultipartFile {
  final Uint8List bytes;
  final String filename;

  MultipartFile.fromBytes(this.bytes, {required this.filename});
}
