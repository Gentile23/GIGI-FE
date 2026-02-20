import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../paywall/paywall_screen.dart';
import '../../../core/services/payment_service.dart';
import '../../../providers/engagement_provider.dart';
import '../challenges/challenges_screen.dart';
import '../referral/referral_screen.dart';
import '../progress/transformation_tracker_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../community/community_goals_screen.dart';
import '../gamification/gamification_screen.dart';
import '../settings/health_settings_screen.dart';
import 'edit_preferences_screen.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.profile,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          ResponsiveUtils.floatingElementPadding(context, baseHeight: 80),
        ),
        children: [
          // User info card
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.user;
              final name =
                  user?.name ?? AppLocalizations.of(context)!.userDefaultName;
              final email = user?.email ?? '';
              final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

              String height = user?.height != null
                  ? '${user!.height!.toInt()} cm'
                  : '--';
              String weight = user?.weight != null
                  ? '${user!.weight!.toInt()} kg'
                  : '--';

              String age = '--';
              if (user?.dateOfBirth != null) {
                final dob = user!.dateOfBirth!;
                final today = DateTime.now();
                int ageVal = today.year - dob.year;
                if (today.month < dob.month ||
                    (today.month == dob.month && today.day < dob.day)) {
                  ageVal--;
                }
                age = ageVal.toString();
              }

              return CleanCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CleanAvatar(
                          initials: initials,
                          size: 100,
                          backgroundColor: CleanTheme.primaryLight,
                          imageUrl: user?.avatarUrl,
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 800,
                              imageQuality: 80,
                            );

                            if (image != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Caricamento immagine...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );

                              final success = await authProvider.uploadAvatar(
                                image,
                              );

                              if (context.mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Immagine profilo aggiornata!',
                                      ),
                                      backgroundColor: CleanTheme.accentGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        authProvider.error ??
                                            'Errore durante il caricamento',
                                      ),
                                      backgroundColor: CleanTheme.accentRed,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CleanTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CleanTheme.backgroundColor,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: CleanTheme.textOnPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          AppLocalizations.of(context)!.heightLabel,
                          height,
                        ),
                        _buildDivider(),
                        _buildStatColumn(
                          AppLocalizations.of(context)!.weightLabel,
                          weight,
                        ),
                        _buildDivider(),
                        _buildStatColumn(
                          AppLocalizations.of(context)!.ageLabel,
                          age,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Subscription card
          Consumer3<AuthProvider, PaymentService, EngagementProvider>(
            builder:
                (context, authProvider, paymentService, engagementProvider, _) {
                  final isPremium =
                      authProvider.user?.subscription?.isActive ?? false;

                  if (isPremium) {
                    return _buildActiveSubscriptionCard(context, authProvider);
                  }

                  return _buildQuickBuySubscriptionCard(
                    context,
                    paymentService,
                    engagementProvider,
                  );
                },
          ),

          const SizedBox(height: 16),
          _buildSocialProof(context),
          const SizedBox(height: 8),
          const LiveUrgencyTimer(),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // REWARDS & LEVEL SECTION
          // ═══════════════════════════════════════════
          CleanSectionHeader(
            title: AppLocalizations.of(context)!.levelAndRewards,
            actionText: AppLocalizations.of(context)!.seeAll,
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GamificationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Consumer<GamificationProvider>(
            builder: (context, gamificationProvider, _) {
              final stats = gamificationProvider.stats;
              final xp = stats?.totalXp ?? 0;
              final level = (xp / 1000).floor() + 1;
              final xpForNextLevel = (level * 1000) - xp;
              final achievementsCount =
                  gamificationProvider.unlockedAchievements.length;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CleanTheme.primaryColor.withValues(alpha: 0.15),
                      CleanTheme.primaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    // Level header
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CleanTheme.primaryColor,
                                CleanTheme.primaryLight,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: CleanTheme.textOnDark,
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
                                'Livello $level',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '$xpForNextLevel ${AppLocalizations.of(context)!.xpForNextLevel}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: CleanTheme.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$xp',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: CleanTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // XP Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((xp % 1000) / 1000).clamp(0.0, 1.0),
                        backgroundColor: CleanTheme.borderSecondary,
                        valueColor: AlwaysStoppedAnimation(
                          CleanTheme.primaryColor,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRewardStat('🏆', '$achievementsCount', 'Badge'),
                        _buildRewardStat(
                          '🔥',
                          '${stats?.currentStreak ?? 0}',
                          'Streak',
                        ),
                        _buildRewardStat(
                          '💪',
                          '${stats?.totalWorkouts ?? 0}',
                          'Workout',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════
          // NEW: Quick Actions Section
          // ═══════════════════════════════════════════
          CleanSectionHeader(title: AppLocalizations.of(context)!.features),
          const SizedBox(height: 12),

          CleanCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.emoji_events_outlined,
                  title: AppLocalizations.of(context)!.challenges,
                  subtitle: AppLocalizations.of(context)!.challengesSubtitle,
                  color: CleanTheme.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChallengesScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.leaderboard_outlined,
                  title: AppLocalizations.of(context)!.leaderboard,
                  subtitle: AppLocalizations.of(context)!.leaderboardSubtitle,
                  color: CleanTheme.accentBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.public_outlined,
                  title: AppLocalizations.of(context)!.community,
                  subtitle: AppLocalizations.of(context)!.communitySubtitle,
                  color: CleanTheme.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunityGoalsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.card_giftcard_outlined,
                  title: AppLocalizations.of(context)!.inviteFriends,
                  subtitle: AppLocalizations.of(context)!.inviteFriendsSubtitle,
                  color: CleanTheme.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReferralScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.photo_library_outlined,
                  title: AppLocalizations.of(context)!.transformation,
                  subtitle: AppLocalizations.of(
                    context,
                  )!.transformationSubtitle,
                  color: CleanTheme.accentGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TransformationTrackerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings section
          CleanSectionHeader(title: AppLocalizations.of(context)!.settings),
          const SizedBox(height: 12),

          CleanCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: AppLocalizations.of(context)!.personalInfo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.fitness_center_outlined,
                  title: AppLocalizations.of(context)!.fitnessGoals,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditPreferencesScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.security_outlined,
                  title: AppLocalizations.of(context)!.privacySecurity,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.monitor_heart_outlined,
                  title: AppLocalizations.of(context)!.healthFitness,
                  subtitle: AppLocalizations.of(context)!.healthFitnessSubtitle,
                  color: CleanTheme.accentRed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          CleanButton(
            text: AppLocalizations.of(context)!.logout,
            icon: Icons.logout,
            backgroundColor: CleanTheme.accentRed.withValues(alpha: 0.1),
            textColor: CleanTheme.accentRed,
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: CleanTheme.borderPrimary);
  }

  Widget _buildActiveSubscriptionCard(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => HapticService.mediumTap(),
      child: LiquidSteelContainer(
        borderRadius: 24,
        enableShine: true,
        border: Border.all(
          color: CleanTheme.accentGold.withValues(alpha: 0.5), // Gold border
          width: 1.5,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: CleanTheme.accentGold, // Gold icon
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.currentPlan,
                    style: GoogleFonts.inter(
                      color: CleanTheme.textOnDark.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.premium,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textOnDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.premiumAccessText,
                style: GoogleFonts.inter(
                  color: CleanTheme.textOnDark.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
              if (authProvider.user?.subscription?.endDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.textOnDark.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Scade il: ${DateFormat('dd/MM/yyyy').format(authProvider.user!.subscription!.endDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.accentGold, // Gold text
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBuySubscriptionCard(
    BuildContext context,
    PaymentService paymentService,
    EngagementProvider engagementProvider,
  ) {
    final isEligibleForTrial = engagementProvider.isEligibleForSpecialOffer;

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: CleanTheme.accentOrange),
                  const SizedBox(width: 8),
                  Text(
                    'PASSA A GIGI PRO',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: CleanTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              if (isEligibleForTrial)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: CleanTheme.accentOrange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: CleanTheme.accentOrange,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '7 GG GRATIS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: CleanTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sblocca il tuo Coach AI',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Side-by-side or stacked options
          Row(
            children: [
              // Yearly Option (Anchoring & High Value)
              Expanded(
                child: _buildDirectPurchaseOption(
                  context,
                  paymentService,
                  title: 'ANNUALE',
                  price: '€8,33/mese',
                  subPrice: '€99,99 totali',
                  badge: 'RISPARMIA 44%',
                  productId: ProductInfo.proYearly,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 12),
              // Monthly Option
              Expanded(
                child: _buildDirectPurchaseOption(
                  context,
                  paymentService,
                  title: 'MENSILE',
                  price: '€14,99',
                  subPrice: 'Ogni mese',
                  productId: ProductInfo.proMonthly,
                  isHighlighted: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaywallScreen(),
                  ),
                );
              },
              child: Text(
                'Vedi tutti i vantaggi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          if (engagementProvider.isEligibleForSpecialOffer) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'L\'offerta scade tra pochi minuti. Non perderla!',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CleanTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDirectPurchaseOption(
    BuildContext context,
    PaymentService paymentService, {
    required String title,
    required String price,
    required String subPrice,
    String? badge,
    required String productId,
    required bool isHighlighted,
  }) {
    // Content of the card
    final content = Column(
      children: [
        if (badge != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.white : CleanTheme.accentOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isHighlighted
                    ? CleanTheme.primaryColor
                    : CleanTheme.textOnDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? Colors.white.withValues(alpha: 0.9) // Lighter for Steel
                : CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? CleanTheme.textOnDark
                : CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subPrice,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isHighlighted
                ? CleanTheme.textOnDark.withValues(alpha: 0.7)
                : CleanTheme.textTertiary,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        _handleDirectPurchase(context, paymentService, productId);
      },
      child: isHighlighted
          ? LiquidSteelContainer(
              borderRadius: 20,
              enableShine: true,
              border: Border.all(
                color: CleanTheme.primaryColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 12,
                ),
                child: content,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CleanTheme.borderSecondary,
                  width: 1.5,
                ),
              ),
              child: content,
            ),
    );
  }

  Widget _buildSocialProof(BuildContext context) {
    // Semi-dynamic social proof (mocked for demo effectiveness)
    final userCount = 10 + (DateTime.now().minute % 20);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.dividerColor),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _buildAvatarCircle('https://i.pravatar.cc/150?u=1', 0),
              _buildAvatarCircle('https://i.pravatar.cc/150?u=2', 12),
              _buildAvatarCircle('https://i.pravatar.cc/150?u=3', 24),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$userCount utenti hanno scelto Gigi Pro nelle ultime 24 ore!',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(String url, double offset) {
    return Padding(
      padding: EdgeInsets.only(left: offset),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CleanTheme.surfaceColor, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 14,
                color: CleanTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDirectPurchase(
    BuildContext context,
    PaymentService paymentService,
    String productId,
  ) async {
    // Mostra caricamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    final success = await paymentService.purchaseProduct(productId);

    // Rimuovi caricamento
    if (context.mounted) Navigator.pop(context);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abbonamento attivato! Benvenuto in GiGi Pro.'),
          backgroundColor: CleanTheme.accentGreen,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentService.errorMessage ?? 'Errore durante l\'acquisto.',
          ),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final tileColor = color ?? CleanTheme.primaryColor;
    final bgColor = color?.withValues(alpha: 0.1) ?? CleanTheme.primaryLight;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: tileColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: CleanTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: CleanTheme.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: CleanTheme.borderSecondary,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildRewardStat(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)!.logoutConfirmationTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)!.logoutConfirmationMessage,
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog

              // Capture navigator before async gap
              final navigator = Navigator.of(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(
                    color: CleanTheme.primaryColor,
                  ),
                ),
              );

              try {
                // Perform logout
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                await authProvider.logout();

                // Close loading dialog and navigate to auth
                if (context.mounted) {
                  navigator.pop(); // Close loading dialog
                  navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
                }
              } catch (e) {
                // Close loading dialog on error
                if (context.mounted) {
                  navigator.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante il logout: $e'),
                      backgroundColor: CleanTheme.accentRed,
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: GoogleFonts.inter(
                color: CleanTheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _heightController.text = user.height?.toString() ?? '';
      _weightController.text = user.weight?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    if (!mounted) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.uploadAvatar(image);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUpdatedSuccess),
            backgroundColor: CleanTheme.primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ??
                  AppLocalizations.of(context)!.saveErrorGeneric,
            ),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.editProfile,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final name = auth.user?.name ?? 'U';
                      final avatarUrl = auth.user?.avatarUrl;
                      return CleanAvatar(
                        initials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        size: 100,
                        backgroundColor: CleanTheme.primaryLight,
                        imageUrl: avatarUrl,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CleanTheme.surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CleanTheme.textOnDark,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: CleanTheme.textOnDark,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Name
              _buildTextField(
                controller: _nameController,
                label: AppLocalizations.of(context)!.fullName,
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.enterYourName;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: AppLocalizations.of(context)!.email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.enterYourEmail;
                  }
                  if (!value.contains('@')) {
                    return AppLocalizations.of(context)!.enterValidEmail;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Height
              _buildTextField(
                controller: _heightController,
                label: AppLocalizations.of(context)!.heightCm,
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Weight
              _buildTextField(
                controller: _weightController,
                label: AppLocalizations.of(context)!.weightKg,
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Save button
              CleanButton(
                text: AppLocalizations.of(context)!.saveChanges,
                width: double.infinity,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        prefixIcon: Icon(icon, color: CleanTheme.textSecondary),
        filled: true,
        fillColor: CleanTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CleanTheme.primaryColor),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );

      try {
        final success = await authProvider.updateProfile(
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.profileUpdatedSuccess,
              ),
              backgroundColor: CleanTheme.primaryColor,
            ),
          );
          Navigator.pop(context); // Return to profile screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error ??
                    AppLocalizations.of(context)!.saveErrorGeneric,
              ),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}

class LiveUrgencyTimer extends StatefulWidget {
  const LiveUrgencyTimer({super.key});

  @override
  State<LiveUrgencyTimer> createState() => _LiveUrgencyTimerState();
}

class _LiveUrgencyTimerState extends State<LiveUrgencyTimer> {
  late Duration _timeRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeRemaining = midnight.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hours = _timeRemaining.inHours;
    final minutes = (_timeRemaining.inMinutes % 60);
    final seconds = (_timeRemaining.inSeconds % 60);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: CleanTheme.accentOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CleanTheme.accentOrange.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flash_on,
              color: CleanTheme.accentOrange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${l10n.paywallUrgencyText}: ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CleanTheme.accentOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
