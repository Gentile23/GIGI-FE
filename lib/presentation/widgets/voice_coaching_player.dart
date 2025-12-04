import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/voice_coaching_model.dart';
import '../../core/theme/modern_theme.dart';
import '../../core/constants/api_config.dart';

class VoiceCoachingController {
  _VoiceCoachingPlayerState? _state;

  void _attach(_VoiceCoachingPlayerState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  Future<void> playPre() async {
    await _state?._playPhase('preparation');
  }

  Future<void> playDuring() async {
    await _state?._playPhase('execution');
  }

  Future<void> playPost() async {
    await _state?._playPhase('closing');
  }

  Future<void> stop() async {
    await _state?._stop();
  }
}

class VoiceCoachingPlayer extends StatefulWidget {
  final VoiceCoaching voiceCoaching;
  final VoidCallback? onUpgrade;
  final VoiceCoachingController? controller;

  const VoiceCoachingPlayer({
    super.key,
    required this.voiceCoaching,
    this.onUpgrade,
    this.controller,
  });

  @override
  State<VoiceCoachingPlayer> createState() => _VoiceCoachingPlayerState();
}

class _VoiceCoachingPlayerState extends State<VoiceCoachingPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isMuted = false;
  bool _showScript = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Structured coaching state
  String _currentPhase = 'preparation'; // 'preparation', 'execution', 'closing'
  int _currentRep = 0; // 0 means not started, 1-N for reps

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _setupAudioPlayer();
  }

  @override
  void didUpdateWidget(VoiceCoachingPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
          _updateCurrentPhaseAndRep();
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        // If controlled externally, we might not want auto-advance
        // But for now, let's just stop and let the controller handle the next phase
        // Or if it's legacy/auto mode, we continue.
        // Given the requirement "synchronized", we likely want to stop and wait for triggers.

        if (widget.controller != null) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        } else {
          // Legacy/Auto behavior
          if (widget.voiceCoaching.isMultiPhase) {
            _advancePhase();
            if (_currentPhase != 'preparation') {
              _playPause();
            } else {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
              });
            }
          } else {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
              _currentPhase = 'preparation';
              _currentRep = 0;
            });
          }
        }
      }
    });
  }

  /// Calculate current phase and repetition based on audio position
  void _updateCurrentPhaseAndRep() {
    if (!widget.voiceCoaching.isStructured) return;

    final structured = widget.voiceCoaching.structuredScript!;
    final positionSeconds = _position.inSeconds;

    // Phase 1: Preparation
    final prepDuration = structured.preparation.durationSeconds;
    if (positionSeconds < prepDuration) {
      _currentPhase = 'preparation';
      _currentRep = 0;
      return;
    }

    // Phase 2: Execution (estimate ~5 seconds per rep)
    final execStartTime = prepDuration;
    final estimatedRepDuration = 5; // seconds per repetition
    final totalExecDuration = structured.totalReps * estimatedRepDuration;
    final execEndTime = execStartTime + totalExecDuration;

    if (positionSeconds < execEndTime) {
      _currentPhase = 'execution';
      final execElapsed = positionSeconds - execStartTime;
      _currentRep = (execElapsed / estimatedRepDuration).floor() + 1;
      // Clamp to valid range
      _currentRep = _currentRep.clamp(1, structured.totalReps);
      return;
    }

    // Phase 3: Closing
    _currentPhase = 'closing';
    _currentRep = structured.totalReps;
  }

  Future<void> _playPhase(String phase) async {
    if (!widget.voiceCoaching.isAvailable) return;

    setState(() {
      _currentPhase = phase;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? audioUrl;
      if (widget.voiceCoaching.isMultiPhase) {
        if (phase == 'preparation') {
          audioUrl = widget.voiceCoaching.multiPhase?.preExercise?.audioUrl;
        } else if (phase == 'execution') {
          audioUrl = widget.voiceCoaching.multiPhase?.duringExecution?.audioUrl;
        } else if (phase == 'closing') {
          audioUrl = widget.voiceCoaching.multiPhase?.postExercise?.audioUrl;
        }
      } else {
        // Legacy fallback - just play the whole file
        audioUrl = widget.voiceCoaching.audioUrl;
      }

      if (audioUrl != null) {
        if (audioUrl.startsWith('/')) {
          final baseUrl = ApiConfig.baseUrl.endsWith('/api')
              ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
              : ApiConfig.baseUrl;
          audioUrl = '$baseUrl$audioUrl';
        }
        await _audioPlayer.stop(); // Stop current before playing new
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      print('Error playing phase $phase: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _playPause() async {
    if (!widget.voiceCoaching.isAvailable) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Multi-phase playback logic
        if (widget.voiceCoaching.isMultiPhase) {
          String? audioUrl;
          if (_currentPhase == 'preparation') {
            audioUrl = widget.voiceCoaching.multiPhase?.preExercise?.audioUrl;
          } else if (_currentPhase == 'execution') {
            audioUrl =
                widget.voiceCoaching.multiPhase?.duringExecution?.audioUrl;
          } else if (_currentPhase == 'closing') {
            audioUrl = widget.voiceCoaching.multiPhase?.postExercise?.audioUrl;
          }

          if (audioUrl != null) {
            // Handle relative URLs
            if (audioUrl.startsWith('/')) {
              // Use configured base URL (remove /api suffix if present to avoid duplication)
              final baseUrl = ApiConfig.baseUrl.endsWith('/api')
                  ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
                  : ApiConfig.baseUrl;
              audioUrl = '$baseUrl$audioUrl';
            }

            // If resuming from pause, just resume
            if (_position > Duration.zero && _position < _duration) {
              await _audioPlayer.resume();
            } else {
              await _audioPlayer.play(UrlSource(audioUrl));
            }
          } else {
            // Skip phase if no audio

            // Prevent infinite loop: only advance if we haven't just cycled through everything
            if (_currentPhase == 'closing' &&
                widget.voiceCoaching.multiPhase?.preExercise?.audioUrl ==
                    null &&
                widget.voiceCoaching.multiPhase?.duringExecution?.audioUrl ==
                    null) {
              // All phases empty, stop
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
                _currentPhase = 'preparation';
              });
              return;
            }

            _advancePhase();
            // Only recurse if we haven't looped back to preparation
            if (_currentPhase != 'preparation') {
              _playPause();
            } else {
              // We looped back to start, stop
              setState(() {
                _isPlaying = false;
              });
            }
            return;
          }
        } else {
          // Legacy single-file playback
          if (_position == Duration.zero) {
            String audioUrl = widget.voiceCoaching.audioUrl!;
            if (audioUrl.startsWith('/')) {
              // Use configured base URL (remove /api suffix if present to avoid duplication)
              final baseUrl = ApiConfig.baseUrl.endsWith('/api')
                  ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
                  : ApiConfig.baseUrl;
              audioUrl = '$baseUrl$audioUrl';
            }
            await _audioPlayer.play(UrlSource(audioUrl));
          } else {
            await _audioPlayer.resume();
          }
        }
      }
    } catch (e) {
      print('Error playing audio: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore durante la riproduzione: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _advancePhase() {
    if (_currentPhase == 'preparation') {
      _currentPhase = 'execution';
    } else if (_currentPhase == 'execution') {
      _currentPhase = 'closing';
    } else {
      _currentPhase = 'preparation';
      _isPlaying = false;
    }
    _position = Duration.zero;
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _position = Duration.zero;
        _currentPhase = 'preparation';
        _currentRep = 0;
      });
    }
  }

  Future<void> _replay() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
      _currentPhase = 'preparation';
      _currentRep = 0;
    });
    // If controlled, maybe just play current phase? Or restart sequence?
    // For now, reuse playPause which handles sequence
    await _playPause();
  }

  void _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void _toggleScript() {
    setState(() => _showScript = !_showScript);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getPhaseLabel() {
    switch (_currentPhase) {
      case 'preparation':
        return '🎯 Preparazione';
      case 'execution':
        return '💪 Esecuzione';
      case 'closing':
        return '✅ Completato';
      default:
        return '';
    }
  }

  Color _getPhaseColor() {
    switch (_currentPhase) {
      case 'preparation':
        return Colors.blue;
      case 'execution':
        return ModernTheme.accentColor;
      case 'closing':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  Widget _buildRepetitionCounter() {
    final structured = widget.voiceCoaching.structuredScript!;
    final progress = _currentRep / structured.totalReps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getPhaseColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPhaseColor().withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Phase indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPhaseLabel(),
                style: TextStyle(
                  color: _getPhaseColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (_currentPhase == 'execution')
                Text(
                  'Rep $_currentRep/${structured.totalReps}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.accentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar for execution phase
          if (_currentPhase == 'execution') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(_getPhaseColor()),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            // Large rep counter
            Text(
              '$_currentRep',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: ModernTheme.accentColor,
                height: 1,
              ),
            ),
          ],
          // Completion message
          if (_currentPhase == 'closing')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${structured.totalReps} ripetizioni completate!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.voiceCoaching.isAvailable) {
      return _buildUpgradePrompt();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ModernTheme.accentColor.withOpacity(0.1),
            ModernTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ModernTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic, color: ModernTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Voice Coaching Live',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ModernTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Script toggle button
              if (widget.voiceCoaching.scriptText != null)
                IconButton(
                  icon: Icon(
                    _showScript ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: _toggleScript,
                  color: Colors.white70,
                  tooltip: _showScript ? 'Nascondi testo' : 'Mostra testo',
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ModernTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: ModernTheme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Repetition Counter (only for structured coaching)
          if (widget.voiceCoaching.isStructured && _isPlaying) ...[
            const SizedBox(height: 16),
            _buildRepetitionCounter(),
          ],

          // Script text (collapsible)
          if (_showScript && widget.voiceCoaching.scriptText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                widget.voiceCoaching.scriptText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _playPause,
                    child: const Text(
                      'Riprova',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: ModernTheme.accentColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: ModernTheme.accentColor,
            ),
            child: Slider(
              value: _duration.inSeconds > 0
                  ? _position.inSeconds / _duration.inSeconds
                  : 0.0,
              onChanged: (value) async {
                final position = Duration(
                  seconds: (value * _duration.inSeconds).round(),
                );
                await _audioPlayer.seek(position);
              },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  _formatDuration(_duration),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mute button
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                color: Colors.white70,
                iconSize: 24,
              ),
              const SizedBox(width: 8),
              // Stop button
              IconButton(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                color: Colors.white70,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              // Play/Pause button
              _isLoading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : IconButton(
                      onPressed: _playPause,
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      color: ModernTheme.accentColor,
                      iconSize: 48,
                      style: IconButton.styleFrom(
                        backgroundColor: ModernTheme.accentColor.withOpacity(
                          0.2,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              // Replay button
              IconButton(
                onPressed: _replay,
                icon: const Icon(Icons.replay),
                color: Colors.white70,
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.lock, color: ModernTheme.accentColor, size: 32),
          const SizedBox(height: 12),
          Text(
            'Voice Coaching Live',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Guida vocale AI per ogni esercizio',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Passa a PRO'),
          ),
        ],
      ),
    );
  }
}
