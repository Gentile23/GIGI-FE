import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/ui_preferences_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';
import 'change_email_screen.dart';
import 'change_password_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh user data to ensure the latest email/status is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).fetchUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final uiPreferences = Provider.of<UiPreferencesService>(context);
    final user = authProvider.user;
    final isPremium = user?.subscription?.isActive ?? false;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sicurezza Account',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: () => authProvider.fetchUser(),
        color: CleanTheme.primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            // Security Status Card
            _buildSecurityStatusCard(context, user?.email ?? ''),
            const SizedBox(height: 32),

            _buildSectionHeader('Accesso e Recupero'),
            const SizedBox(height: 12),
            CleanCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSecurityTile(
                    context,
                    icon: Icons.alternate_email,
                    title: 'Email',
                    subtitle: user?.email ?? 'Non impostata',
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangeEmailScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).fetchUser();
                          }
                        }),
                  ),
                  _buildDivider(),
                  _buildSecurityTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Password',
                    subtitle: 'Ultimo aggiornamento: recente',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            if (isPremium) ...[
              _buildSectionHeader('Aspetto Pro'),
              const SizedBox(height: 12),
              CleanCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildToggleTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Bordo oro menu',
                      subtitle:
                          'Mostra un microbordo dorato intorno al menu in basso',
                      value: uiPreferences.proBottomBarAccentEnabled,
                      onChanged: uiPreferences.setProBottomBarAccentEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            _buildSectionHeader('Altre Opzioni'),
            const SizedBox(height: 12),
            CleanCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSecurityTile(
                    context,
                    icon: Icons.delete_forever_outlined,
                    title: l10n.deleteAccountTitle,
                    subtitle: 'Rimuovi tutti i tuoi dati',
                    color: CleanTheme.accentRed,
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'GIGI Security Engine v2.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor,
            CleanTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Protetto',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Il tuo account è collegato a $email',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: CleanTheme.textSecondary,
      ),
    );
  }

  Widget _buildSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? CleanTheme.textPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: tileColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: tileColor),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: CleanTheme.textSecondary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: CleanTheme.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: CleanTheme.borderSecondary,
      indent: 72,
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      value: value,
      onChanged: onChanged,
      activeThumbColor: CleanTheme.accentGold,
      activeTrackColor: CleanTheme.accentGold.withValues(alpha: 0.35),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CleanTheme.accentGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: CleanTheme.accentGold, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: CleanTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: CleanTheme.textSecondary),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: CleanTheme.accentRed,
            ),
            const SizedBox(width: 12),
            Text(
              'Elimina Account',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: CleanTheme.accentRed,
              ),
            ),
          ],
        ),
        content: Text(
          'Questa azione è irreversibile. Tutti i tuoi progressi, abbonamenti e dati verranno eliminati definitivamente.',
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CleanButton(
            text: 'Elimina',
            backgroundColor: CleanTheme.accentRed,
            onPressed: () async {
              Navigator.pop(context);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await auth.deleteAccount();
              if (success && context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth', (route) => false);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      auth.error ?? 'Errore durante l\'eliminazione',
                    ),
                    backgroundColor: CleanTheme.accentRed,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
