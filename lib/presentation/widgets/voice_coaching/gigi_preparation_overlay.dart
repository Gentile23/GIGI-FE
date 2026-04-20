import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/synchronized_voice_controller.dart';
import '../workout/dual_anatomical_view.dart';

/// Animated overlay that shows preparation cards during audio generation.
/// Long-press the card to pause auto-advance while reading.
class GigiPreparationOverlay extends StatefulWidget {
  final List<PreparationCard> cards;
  final VoidCallback onClose;
  final VoidCallback onSkip;
  final VoidCallback onAllCardsShown;
  final bool isAudioReady;
  final List<String> muscleGroups;
  final List<String> secondaryMuscleGroups;

  const GigiPreparationOverlay({
    super.key,
    required this.cards,
    required this.onClose,
    required this.onSkip,
    required this.onAllCardsShown,
    this.isAudioReady = false,
    this.muscleGroups = const [],
    this.secondaryMuscleGroups = const [],
  });

  @override
  State<GigiPreparationOverlay> createState() => _GigiPreparationOverlayState();
}

class _GigiPreparationOverlayState extends State<GigiPreparationOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _autoAdvanceTimer;
  bool _isPausedForReading = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _startAutoAdvance();
  }

  @override
  void didUpdateWidget(covariant GigiPreparationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      setState(() => _currentIndex = 0);
      _fadeController.forward(from: 0);
      if (!_isPausedForReading) _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _isPausedForReading) return;
      _advanceCard();
    });
  }

  void _advanceCard() {
    if (_currentIndex < widget.cards.length - 1) {
      _fadeController.reverse().then((_) {
        if (!mounted || _isPausedForReading) return;
        setState(() => _currentIndex++);
        _fadeController.forward();
      });
    } else {
      widget.onAllCardsShown();
    }
  }

  void _pauseForReading() {
    if (_isPausedForReading) return;
    setState(() => _isPausedForReading = true);
    _autoAdvanceTimer?.cancel();
  }

  void _resumeAfterReading() {
    if (!_isPausedForReading) return;
    setState(() => _isPausedForReading = false);
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();

    final card = widget.cards[_currentIndex.clamp(0, widget.cards.length - 1)];
    final isMuscleCard =
        card.title.toLowerCase().contains('muscoli') &&
        widget.muscleGroups.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) => _pauseForReading(),
            onLongPressEnd: (_) => _resumeAfterReading(),
            onLongPressCancel: _resumeAfterReading,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCardContent(card, isMuscleCard),
                  ),
                ),
                const SizedBox(height: 32),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PREPARAZIONE',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(PreparationCard card, bool isMuscleCard) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          child: Text(card.icon, style: const TextStyle(fontSize: 42)),
        ),
        const SizedBox(height: 18),
        Text(
          card.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (isMuscleCard) ...[
          _buildMusclePreview(),
          const SizedBox(height: 10),
          _buildMuscleLegend(),
          const SizedBox(height: 10),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            card.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusclePreview() {
    return Container(
      height: 130,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DualAnatomicalView(
        muscleGroups: widget.muscleGroups,
        secondaryMuscleGroups: widget.secondaryMuscleGroups,
        height: 118,
      ),
    );
  }

  Widget _buildMuscleLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendDot(color: const Color(0xFFE53935), label: 'Primari'),
        if (widget.secondaryMuscleGroups.isNotEmpty) ...[
          const SizedBox(width: 12),
          _buildLegendDot(color: const Color(0xFFEF9A9A), label: 'Secondari'),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(child: _buildDots()),
        if (_isPausedForReading) ...[
          const SizedBox(width: 10),
          Text(
            'PAUSA LETTURA',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 1,
            ),
          ),
        ],
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: widget.isAudioReady ? _buildSkipButton() : _buildWaitingText(),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      children: List.generate(widget.cards.length, (i) {
        final isActive = i == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      CleanTheme.primaryColor,
                      CleanTheme.primaryColor.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      key: const ValueKey('skip_btn'),
      onTap: widget.onSkip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CleanTheme.primaryColor,
              CleanTheme.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: CleanTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SALTA',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingText() {
    return Text(
      'QUASI PRONTO...',
      key: const ValueKey('skip_hidden'),
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}
