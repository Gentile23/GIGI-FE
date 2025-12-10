import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/clean_theme.dart';

class ExerciseVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final String exerciseName;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) return;

    try {
      final videoId = YoutubePlayerController.convertUrlToId(widget.videoUrl!);
      if (videoId != null) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showControls: true,
            mute: false,
            showFullscreenButton: true,
            loop: true,
            enableCaption: false,
            playsInline: true,
          ),
        );
      } else {
        _hasError = true;
      }
    } catch (e) {
      debugPrint('Error initializing YouTube player: $e');
      _hasError = true;
    }
  }

  @override
  void didUpdateWidget(ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.close();
      _controller = null;
      _hasError = false;
      _initializePlayer();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_controller == null || _hasError) {
      return _buildErrorWidget();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CleanTheme.borderSecondary,
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam_off, color: CleanTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Video non disponibile',
                  style: TextStyle(
                    color: CleanTheme.textTertiary,
                    fontSize: 14,
                  ),
                ),
                if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      // Open in external browser on mobile, or new tab on web
                      // You can add url_launcher here if needed
                    },
                    child: Text(
                      'Apri su YouTube',
                      style: TextStyle(
                        color: CleanTheme.accentBlue,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
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
}
