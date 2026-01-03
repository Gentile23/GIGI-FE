import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../paywall/paywall_screen.dart';
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
        actions: [
          CleanIconButton(
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            hasBorder: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                    CleanAvatar(
                      initials: initials,
                      size: 100,
                      backgroundColor: CleanTheme.primaryLight,
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
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final isPremium =
                  authProvider.user?.subscription?.isActive ?? false;
              final planName = isPremium
                  ? AppLocalizations.of(context)!.premium
                  : AppLocalizations.of(context)!.freeTier;

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA000),
                          ] // Gold for premium
                        : [CleanTheme.primaryColor, const Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isPremium
                                  ? const Color(0xFFFFD700)
                                  : CleanTheme.primaryColor)
                              .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (!isPremium) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PaywallScreen(),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.currentPlan,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            planName,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isPremium
                                ? AppLocalizations.of(
                                    context,
                                  )!.premiumAccessText
                                : AppLocalizations.of(
                                    context,
                                  )!.upgradeToPremiumText,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                          if (!isPremium) ...[
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.upgradeToPremiumButton,
                                  style: GoogleFonts.inter(
                                    color: CleanTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

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
                      CleanTheme.accentPurple.withValues(alpha: 0.15),
                      CleanTheme.primaryColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CleanTheme.accentPurple.withValues(alpha: 0.3),
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
                                CleanTheme.accentPurple,
                                CleanTheme.primaryColor,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CleanTheme.accentPurple.withValues(
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
                                color: Colors.white,
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
                          CleanTheme.accentPurple,
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
                  color: CleanTheme.accentPurple,
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
                  color: const Color(0xFFE91E63),
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
                  icon: Icons.notifications_outlined,
                  title: AppLocalizations.of(context)!.notifications,
                  onTap: () {},
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
                  icon: Icons.favorite_outline,
                  title: AppLocalizations.of(context)!.healthFitness,
                  subtitle: AppLocalizations.of(context)!.healthFitnessSubtitle,
                  color: const Color(0xFFE91E63),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)!.helpSupport,
                  onTap: () {},
                ),
                _buildSettingsDivider(),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: AppLocalizations.of(context)!.info,
                  onTap: () {},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Modifica Profilo',
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
                      return CleanAvatar(
                        initials: name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        size: 100,
                        backgroundColor: CleanTheme.primaryLight,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Name
              _buildTextField(
                controller: _nameController,
                label: 'Nome Completo',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il tuo nome';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la tua email';
                  }
                  if (!value.contains('@')) {
                    return 'Inserisci un\'email valida';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Height
              _buildTextField(
                controller: _heightController,
                label: 'Altezza (cm)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Weight
              _buildTextField(
                controller: _weightController,
                label: 'Peso (kg)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Save button
              CleanButton(
                text: 'Salva Modifiche',
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
            const SnackBar(
              content: Text('Profilo aggiornato con successo'),
              backgroundColor: CleanTheme.primaryColor,
            ),
          );
          Navigator.pop(context); // Return to profile screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.error ?? 'Errore durante il salvataggio',
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
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}
