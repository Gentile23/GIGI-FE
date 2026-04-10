import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/clean_theme.dart';

class ExerciseVideoPlayer extends StatelessWidget {
  final String? videoUrl;
  final String exerciseName;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(videoUrl);
    if (videoUrl == null || videoUrl!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    if (videoId == null) {
      return _buildUnavailableCard(
        icon: Icons.link_off_rounded,
        title: 'URL video non valido',
        subtitle: 'Il link associato a questo esercizio non e valido.',
      );
    }

    return GestureDetector(
      onTap: () => _openExternally(context, videoId),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
          image: DecorationImage(
            image: NetworkImage(
              YoutubePlayerController.getThumbnail(
                videoId: videoId,
                quality: ThumbnailQuality.high,
                webp: false,
              ),
            ),
            fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: CleanTheme.textOnDark,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: CleanTheme.textOnDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guarda su YouTube',
                      style: GoogleFonts.outfit(
                        color: CleanTheme.textOnDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractVideoId(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    final converted = YoutubePlayerController.convertUrlToId(trimmed);
    if (converted != null) return converted;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    if (host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.length == 11) return videoId;

      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final markerIndex = segments.indexWhere(
          (segment) => segment == 'embed' || segment == 'shorts',
        );
        if (markerIndex >= 0 && markerIndex + 1 < segments.length) {
          final candidate = segments[markerIndex + 1];
          if (candidate.length == 11) return candidate;
        }
      }
    }

    if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      final candidate = uri.pathSegments.first;
      if (candidate.length == 11) return candidate;
    }

    return null;
  }

  Future<void> _openExternally(BuildContext context, String videoId) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;

    final fallbackLaunched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );
    if (fallbackLaunched || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video non disponibile'),
        backgroundColor: CleanTheme.accentRed,
      ),
    );
  }

  Widget _buildUnavailableCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CleanTheme.surfaceColor,
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Row(
        children: [
          Icon(icon, color: CleanTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: CleanTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }
}
