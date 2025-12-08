import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/addiction_mechanics_model.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// REFERRAL SCREEN - Invite Friends & Earn Rewards
/// ═══════════════════════════════════════════════════════════

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  // Mock referral data - would come from backend
  final ReferralData _referralData = const ReferralData(
    referralCode: 'GIGI2024',
    totalReferrals: 3,
    pendingReferrals: 1,
    convertedReferrals: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invita Amici',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner
            _buildHeroBanner(),

            const SizedBox(height: 24),

            // Referral Code Section
            _buildReferralCodeSection(),

            const SizedBox(height: 24),

            // Progress to Next Reward
            _buildProgressSection(),

            const SizedBox(height: 24),

            // Rewards Milestones
            _buildRewardsMilestones(),

            const SizedBox(height: 24),

            // Share Buttons
            _buildShareButtons(),

            const SizedBox(height: 24),

            // Stats
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.accentPurple,
            CleanTheme.accentPurple.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Regala 1 Mese Premium',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Invita un amico e ricevete entrambi\n1 mese di Premium gratis!',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Il tuo codice referral',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: CleanTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _referralData.referralCode,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.primaryColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _copyCode,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Condividi questo codice con i tuoi amici',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final nextMilestone = _referralData.nextMilestone;
    final reward = ReferralData.milestoneRewards[nextMilestone];

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Prossimo premio',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_referralData.convertedReferrals}/$nextMilestone inviti',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.accentPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _referralData.progressToNextMilestone,
              backgroundColor: CleanTheme.borderSecondary,
              color: CleanTheme.accentPurple,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          if (reward != null)
            Row(
              children: [
                Text(reward.iconEmoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        reward.description,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRewardsMilestones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premi Referral',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...ReferralData.milestoneRewards.entries.map((entry) {
          final milestone = entry.key;
          final reward = entry.value;
          final isUnlocked = _referralData.convertedReferrals >= milestone;
          final isNext = _referralData.nextMilestone == milestone;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                  : isNext
                  ? CleanTheme.accentPurple.withValues(alpha: 0.05)
                  : CleanTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked
                    ? CleanTheme.accentGreen.withValues(alpha: 0.3)
                    : isNext
                    ? CleanTheme.accentPurple.withValues(alpha: 0.3)
                    : CleanTheme.borderPrimary,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? CleanTheme.accentGreen
                        : CleanTheme.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isUnlocked
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '$milestone',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked
                              ? CleanTheme.accentGreen
                              : CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        reward.description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  reward.iconEmoji,
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked
                        ? null
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condividi',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.message,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE4405F),
                onTap: () => _shareToInstagram(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.share,
                label: 'Altro',
                color: CleanTheme.primaryColor,
                onTap: () => _shareGeneral(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              value: '${_referralData.totalReferrals}',
              label: 'Totali',
              icon: Icons.people_outline,
            ),
          ),
          Container(width: 1, height: 40, color: CleanTheme.borderPrimary),
          Expanded(
            child: _buildStatItem(
              value: '${_referralData.pendingReferrals}',
              label: 'In attesa',
              icon: Icons.hourglass_empty,
            ),
          ),
          Container(width: 1, height: 40, color: CleanTheme.borderPrimary),
          Expanded(
            child: _buildStatItem(
              value: '${_referralData.convertedReferrals}',
              label: 'Convertiti',
              icon: Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: CleanTheme.textSecondary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralData.referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codice copiato! 📋'),
        backgroundColor: CleanTheme.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareToWhatsApp() {
    final message =
        'Prova GIGI, la migliore app fitness con AI coach! Usa il mio codice ${_referralData.referralCode} per 1 mese Premium gratis 💪🔥';
    // In production: url_launcher to open WhatsApp
    _showSharePreview(message);
  }

  void _shareToInstagram() {
    _showSharePreview('Shared to Instagram Stories');
  }

  void _shareGeneral() {
    final message =
        'Prova GIGI, la migliore app fitness con AI coach! Usa il mio codice ${_referralData.referralCode} per 1 mese Premium gratis 💪🔥\n\nScarica: https://gigi.app';
    _showSharePreview(message);
  }

  void _showSharePreview(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Condividi: $message'),
        backgroundColor: CleanTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
