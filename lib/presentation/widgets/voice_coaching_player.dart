import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/voice_coaching_model.dart';
import '../../core/theme/clean_theme.dart';
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

  void _updateCurrentPhaseAndRep() {
    if (!widget.voiceCoaching.isStructured) return;

    final structured = widget.voiceCoaching.structuredScript!;
    final positionSeconds = _position.inSeconds;

    final prepDuration = structured.preparation.durationSeconds;
    if (positionSeconds < prepDuration) {
      _currentPhase = 'preparation';
      _currentRep = 0;
      return;
    }

    final execStartTime = prepDuration;
    final estimatedRepDuration = 5;
    final totalExecDuration = structured.totalReps * estimatedRepDuration;
    final execEndTime = execStartTime + totalExecDuration;

    if (positionSeconds < execEndTime) {
      _currentPhase = 'execution';
      final execElapsed = positionSeconds - execStartTime;
      _currentRep = (execElapsed / estimatedRepDuration).floor() + 1;
      _currentRep = _currentRep.clamp(1, structured.totalReps);
      return;
    }

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
        audioUrl = widget.voiceCoaching.audioUrl;
      }

      if (audioUrl != null) {
        if (audioUrl.startsWith('/')) {
          final baseUrl = ApiConfig.baseUrl.endsWith('/api')
              ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
              : ApiConfig.baseUrl;
          audioUrl = '$baseUrl$audioUrl';
        }
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint('Error playing phase $phase: $e');
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
            if (audioUrl.startsWith('/')) {
              final baseUrl = ApiConfig.baseUrl.endsWith('/api')
                  ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 4)
                  : ApiConfig.baseUrl;
              audioUrl = '$baseUrl$audioUrl';
            }

            if (_position > Duration.zero && _position < _duration) {
              await _audioPlayer.resume();
            } else {
              await _audioPlayer.play(UrlSource(audioUrl));
            }
          } else {
            if (_currentPhase == 'closing' &&
                widget.voiceCoaching.multiPhase?.preExercise?.audioUrl ==
                    null &&
                widget.voiceCoaching.multiPhase?.duringExecution?.audioUrl ==
                    null) {
              setState(() {
                _isPlaying = false;
                _position = Duration.zero;
                _currentPhase = 'preparation';
              });
              return;
            }

            _advancePhase();
            if (_currentPhase != 'preparation') {
              _playPause();
            } else {
              setState(() {
                _isPlaying = false;
              });
            }
            return;
          }
        } else {
          if (_position == Duration.zero) {
            String audioUrl = widget.voiceCoaching.audioUrl!;
            if (audioUrl.startsWith('/')) {
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
      debugPrint('Error playing audio: $e');
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
        return CleanTheme.accentBlue;
      case 'execution':
        return CleanTheme.primaryColor;
      case 'closing':
        return CleanTheme.accentGreen;
      default:
        return CleanTheme.textPrimary;
    }
  }

  Widget _buildRepetitionCounter() {
    final structured = widget.voiceCoaching.structuredScript!;
    final progress = _currentRep / structured.totalReps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getPhaseColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPhaseColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getPhaseLabel(),
                style: GoogleFonts.inter(
                  color: _getPhaseColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (_currentPhase == 'execution')
                Text(
                  'Rep $_currentRep/${structured.totalReps}',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_currentPhase == 'execution') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: CleanTheme.borderSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(_getPhaseColor()),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_currentRep',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: CleanTheme.primaryColor,
                height: 1,
              ),
            ),
          ],
          if (_currentPhase == 'closing')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: CleanTheme.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${structured.totalReps} ripetizioni completate!',
                  style: GoogleFonts.inter(
                    color: CleanTheme.accentGreen,
                    fontWeight: FontWeight.w600,
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
        color: CleanTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_outlined,
                color: CleanTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Voice Coaching Live',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (widget.voiceCoaching.scriptText != null)
                IconButton(
                  icon: Icon(
                    _showScript ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: _toggleScript,
                  color: CleanTheme.textSecondary,
                  tooltip: _showScript ? 'Nascondi testo' : 'Mostra testo',
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.inter(
                    color: CleanTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          if (widget.voiceCoaching.isStructured && _isPlaying) ...[
            const SizedBox(height: 16),
            _buildRepetitionCounter(),
          ],

          if (_showScript && widget.voiceCoaching.scriptText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Text(
                widget.voiceCoaching.scriptText!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CleanTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CleanTheme.accentRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: CleanTheme.accentRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        color: CleanTheme.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _playPause,
                    child: Text(
                      'Riprova',
                      style: GoogleFonts.inter(fontSize: 12),
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
              activeTrackColor: CleanTheme.primaryColor,
              inactiveTrackColor: CleanTheme.borderSecondary,
              thumbColor: CleanTheme.primaryColor,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _toggleMute,
                icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                color: CleanTheme.textSecondary,
                iconSize: 24,
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _stop,
                icon: const Icon(Icons.stop),
                color: CleanTheme.textSecondary,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              _isLoading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: CleanTheme.primaryColor,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _playPause,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        color: CleanTheme.primaryColor,
                        iconSize: 48,
                      ),
                    ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _replay,
                icon: const Icon(Icons.replay),
                color: CleanTheme.textSecondary,
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
        color: CleanTheme.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outlined, color: CleanTheme.accentPurple, size: 32),
          const SizedBox(height: 12),
          Text(
            'Voice Coaching Live',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guida vocale AI per ogni esercizio',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onUpgrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.accentPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Passa a PRO',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
