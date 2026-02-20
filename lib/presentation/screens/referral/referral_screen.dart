import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/referral_service.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';

/// ═══════════════════════════════════════════════════════════
/// REFERRAL SCREEN - Invite Friends & Earn Rewards
/// ═══════════════════════════════════════════════════════════

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late ReferralService _referralService;
  bool _isLoading = true;
  String? _error;

  // Referral data from API
  String _referralCode = '';
  int _convertedReferrals = 0;
  int _totalReferrals = 0;
  bool _hasEarnedReward = false;
  bool _rewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _referralService = ReferralService(context.read<ApiClient>());
    _loadReferralData();
  }

  /// Helper to safely parse boolean values that may come as int (0/1) from backend
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _referralService.getStats();

      if (result['success'] == true) {
        setState(() {
          _referralCode = result['referral_code'] ?? '';
          _convertedReferrals = result['converted_referrals'] ?? 0;
          _totalReferrals = result['total_referrals'] ?? 0;
          _hasEarnedReward = _parseBool(result['has_earned_reward']);
          _rewardClaimed = _parseBool(result['reward_claimed']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Errore nel caricamento';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int get _invitesUntilReward => (3 - _convertedReferrals).clamp(0, 3);
  double get _progressToReward => _convertedReferrals / 3;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: CleanTheme.accentRed),
                  ),
                  const SizedBox(height: 16),
                  CleanButton(onPressed: _loadReferralData, text: 'Riprova'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroBanner(),
                    const SizedBox(height: 24),
                    _buildReferralCodeSection(),
                    const SizedBox(height: 24),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildRewardCard(),
                    const SizedBox(height: 24),
                    _buildShareButtons(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    return LiquidSteelContainer(
      borderRadius: 24,
      enableShine: true,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Invita 3 amici e ricevi\n1 mese di Premium gratis!',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.yourReferralCode,
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
                  _referralCode,
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
                '$_convertedReferrals/3 inviti',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progressToReward.clamp(0.0, 1.0),
              backgroundColor: CleanTheme.borderSecondary,
              color: _hasEarnedReward
                  ? CleanTheme.accentGreen
                  : CleanTheme.primaryColor,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 Mese Premium Gratis',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _hasEarnedReward
                            ? CleanTheme.accentGreen
                            : CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _hasEarnedReward
                          ? (_rewardClaimed
                                ? 'Premio già riscattato!'
                                : 'Premio sbloccato! Riscattalo!')
                          : 'Mancano $_invitesUntilReward inviti',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _hasEarnedReward
                            ? CleanTheme.accentGreen
                            : CleanTheme.textSecondary,
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

  Widget _buildRewardCard() {
    final isUnlocked = _hasEarnedReward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
            : CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? CleanTheme.accentGreen.withValues(alpha: 0.3)
              : CleanTheme.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? CleanTheme.accentGreen
                  : CleanTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isUnlocked
                  ? const Icon(Icons.check, color: Colors.white, size: 24)
                  : Text(
                      '3',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
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
                  '1 Mese Premium Gratis',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked
                        ? CleanTheme.accentGreen
                        : CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  'Invita 3 amici per ottenerlo',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked && !_rewardClaimed)
            ElevatedButton(
              onPressed: _claimReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: CleanTheme.accentGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Riscatta'),
            )
          else
            Text(
              '🎁',
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
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
                onTap: _shareToWhatsApp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.camera_alt,
                label: 'Instagram',
                color: const Color(0xFFE4405F),
                onTap: _shareToInstagram,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                icon: Icons.share,
                label: 'Altro',
                color: CleanTheme.primaryColor,
                onTap: _shareGeneral,
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
              value: '$_totalReferrals',
              label: AppLocalizations.of(context)!.totalReferrals,
              icon: Icons.people_outline,
            ),
          ),
          Container(width: 1, height: 40, color: CleanTheme.borderPrimary),
          Expanded(
            child: _buildStatItem(
              value: '$_convertedReferrals',
              label: AppLocalizations.of(context)!.convertedReferrals,
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
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Codice copiato! 📋'),
        backgroundColor: CleanTheme.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _claimReward() async {
    final result = await _referralService.claimReward();

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Premio riscattato!'),
          backgroundColor: CleanTheme.accentGreen,
        ),
      );
      _loadReferralData(); // Refresh data
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Errore nel riscatto'),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }

  void _shareToWhatsApp() {
    final message =
        'Prova GIGI, la migliore app fitness con AI coach! Usa il mio codice $_referralCode per 1 mese Premium gratis 💪🔥';
    _showSharePreview(message);
  }

  void _shareToInstagram() {
    _showSharePreview('Shared to Instagram Stories');
  }

  void _shareGeneral() {
    final message =
        'Prova GIGI, la migliore app fitness con AI coach! Usa il mio codice $_referralCode per 1 mese Premium gratis 💪🔥\n\nScarica: https://gigi.app';
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
