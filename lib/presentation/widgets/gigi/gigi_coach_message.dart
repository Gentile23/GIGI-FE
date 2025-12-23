import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';

enum GigiEmotion { happy, expert, motivational, celebrating }

class GigiCoachMessage extends StatelessWidget {
  final String message;
  final GigiEmotion emotion;
  final Widget? action;
  final bool isCompact;

  const GigiCoachMessage({
    super.key,
    required this.message,
    this.emotion = GigiEmotion.happy,
    this.action,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGigiAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpeechBubble(context),
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGigiAvatar() {
    return Container(
      width: isCompact ? 48 : 60,
      height: isCompact ? 48 : 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/images/gigi_trainer.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildSpeechBubble(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'GIGI',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CleanTheme.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(_getEmotionIcon(), size: 14, color: CleanTheme.primaryColor),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: isCompact ? 14 : 15,
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  IconData _getEmotionIcon() {
    switch (emotion) {
      case GigiEmotion.happy:
        return Icons.sentiment_satisfied_alt;
      case GigiEmotion.expert:
        return Icons.auto_awesome;
      case GigiEmotion.motivational:
        return Icons.bolt;
      case GigiEmotion.celebrating:
        return Icons.celebration;
    }
  }
}
