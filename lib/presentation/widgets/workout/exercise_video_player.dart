import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) return;

    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl!);
      if (videoId != null) {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
            loop: true,
          ),
        );
        _controller!.addListener(() {
          if (_controller!.value.isReady && !_isPlayerReady) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing YouTube player: $e');
    }
  }

  @override
  void didUpdateWidget(ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isPlayerReady = false;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_controller == null) {
      return _buildErrorWidget();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: CleanTheme.primaryColor,
          progressColors: const ProgressBarColors(
            playedColor: CleanTheme.primaryColor,
            handleColor: CleanTheme.primaryColor,
          ),
          onReady: () {
            setState(() {
              _isPlayerReady = true;
            });
          },
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            RemainingDuration(),
            const PlaybackSpeedButton(),
            FullScreenButton(),
          ],
        ),
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
      child: const Row(
        children: [
          Icon(Icons.videocam_off, color: CleanTheme.textTertiary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Video non disponibile',
              style: TextStyle(color: CleanTheme.textTertiary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
