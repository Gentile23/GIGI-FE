import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/clean_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// SOCIAL SHARING SERVICE - Viral Sharing Templates
/// ═══════════════════════════════════════════════════════════

class SocialSharingService {
  static final SocialSharingService _instance =
      SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  /// Share workout completion
  Future<void> shareWorkoutCompletion({
    required int duration,
    required int exercises,
    required int calories,
    required int streak,
    required int xpEarned,
  }) async {
    final message =
        '''
💪 Ho appena completato un workout con GIGI!

⏱️ $duration minuti
🏋️ $exercises esercizi
🔥 $calories calorie bruciate
📈 Streak: $streak giorni
⭐ +$xpEarned XP guadagnati

Scarica GIGI e inizia il tuo percorso fitness!
🔗 https://gigi.app/download

#GIGI #Fitness #Workout #FitnessMotivation
''';

    await Share.share(message, subject: 'Il mio workout GIGI');
  }

  /// Share transformation/progress
  Future<void> shareTransformation({
    required double weightLost,
    required int daysActive,
    String? imagePath,
  }) async {
    final message =
        '''
🎯 La mia trasformazione con GIGI!

📉 ${weightLost.toStringAsFixed(1)} kg persi
📅 $daysActive giorni di allenamento
💪 Risultati reali, nessuna scorciatoia

Se ce l'ho fatta io, puoi farcela anche tu!
Scarica GIGI: https://gigi.app/download

#GIGITransformation #FitnessJourney #BeforeAndAfter
''';

    if (imagePath != null) {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: message,
        subject: 'La mia trasformazione GIGI',
      );
    } else {
      await Share.share(message, subject: 'La mia trasformazione GIGI');
    }
  }

  /// Share achievement/badge unlock
  Future<void> shareAchievement({
    required String achievementName,
    required String achievementEmoji,
    required String description,
  }) async {
    final message =
        '''
$achievementEmoji Ho sbloccato un nuovo badge su GIGI!

🏆 $achievementName
$description

Sfida i tuoi amici su GIGI!
🔗 https://gigi.app/download

#GIGI #Achievement #FitnessGoals
''';

    await Share.share(message, subject: 'Nuovo badge GIGI!');
  }

  /// Share streak milestone
  Future<void> shareStreakMilestone({required int streakDays}) async {
    String emoji;
    String milestone;

    if (streakDays >= 100) {
      emoji = '💎';
      milestone = 'LEGGENDARIO';
    } else if (streakDays >= 30) {
      emoji = '🔥';
      milestone = 'ON FIRE';
    } else if (streakDays >= 7) {
      emoji = '⚡';
      milestone = 'UNSTOPPABLE';
    } else {
      emoji = '✨';
      milestone = 'GETTING STARTED';
    }

    final message =
        '''
$emoji $streakDays GIORNI DI STREAK! $emoji

📈 Status: $milestone
💪 $streakDays giorni consecutivi di allenamento

La costanza batte il talento!
Unisciti a me su GIGI: https://gigi.app/download

#GIGI #FitnessStreak #Consistency #Motivation
''';

    await Share.share(message, subject: 'Streak $streakDays giorni!');
  }

  /// Share challenge completion
  Future<void> shareChallengeCompletion({
    required String challengeName,
    required int rank,
    required int totalParticipants,
  }) async {
    final message =
        '''
🏆 Ho completato la sfida "$challengeName" su GIGI!

🥇 Posizione: #$rank su $totalParticipants partecipanti
📈 Sfida completata al 100%

Accetti la sfida?
🔗 https://gigi.app/download

#GIGI #FitnessChallenge #Competition
''';

    await Share.share(message, subject: 'Sfida completata!');
  }

  /// Share referral code
  Future<void> shareReferralCode({
    required String referralCode,
    required String userName,
  }) async {
    final message =
        '''
🎁 $userName ti regala 1 MESE PREMIUM GRATIS su GIGI!

GIGI è l'app fitness con AI coach che ti aiuta a raggiungere i tuoi obiettivi.

✨ Usa il codice: $referralCode
📲 Scarica: https://gigi.app/r/$referralCode

Cosa ottieni:
• AI Personal Trainer
• Voice Coaching durante gli esercizi
• Piano alimentare personalizzato
• Sfide e community

#GIGI #FitnessApp #FreeMonth
''';

    await Share.share(message, subject: '1 mese Premium GIGI gratis!');
  }

  /// Share to specific platform
  Future<void> shareToWhatsApp({required String message}) async {
    // WhatsApp uses the same share mechanism
    await Share.share(message);
  }
}

/// ═══════════════════════════════════════════════════════════
/// SHARE RESULT BOTTOM SHEET
/// ═══════════════════════════════════════════════════════════

class ShareResultBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ShareOption> options;

  const ShareResultBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<ShareOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareResultBottomSheet(
        title: title,
        subtitle: subtitle,
        options: options,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: CleanTheme.borderPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Options Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: options
                .map((option) => _buildShareOption(context, option))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, ShareOption option) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        option.onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ShareOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Pre-built share options
class ShareOptions {
  static ShareOption whatsapp(VoidCallback onTap) => ShareOption(
    icon: Icons.message,
    label: 'WhatsApp',
    color: const Color(0xFF25D366),
    onTap: onTap,
  );

  static ShareOption instagram(VoidCallback onTap) => ShareOption(
    icon: Icons.camera_alt,
    label: 'Instagram',
    color: const Color(0xFFE4405F),
    onTap: onTap,
  );

  static ShareOption twitter(VoidCallback onTap) => ShareOption(
    icon: Icons.alternate_email,
    label: 'Twitter',
    color: const Color(0xFF1DA1F2),
    onTap: onTap,
  );

  static ShareOption copyLink(VoidCallback onTap) => ShareOption(
    icon: Icons.link,
    label: 'Copia Link',
    color: CleanTheme.textSecondary,
    onTap: onTap,
  );

  static ShareOption more(VoidCallback onTap) => ShareOption(
    icon: Icons.more_horiz,
    label: 'Altro',
    color: CleanTheme.primaryColor,
    onTap: onTap,
  );
}
