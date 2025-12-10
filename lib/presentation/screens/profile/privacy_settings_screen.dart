import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _notificationsEnabled = true;
  bool _marketingEnabled = false;
  bool _analyticsEnabled = true;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Privacy & Sicurezza',
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: CleanTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I tuoi dati, i tuoi diritti',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gestisci come utilizziamo i tuoi dati personali',
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
          ),

          const SizedBox(height: 24),

          // Consent Management
          CleanSectionHeader(title: 'Gestione Consensi'),
          const SizedBox(height: 12),

          CleanCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildToggleTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifiche Push',
                  subtitle: 'Promemoria allenamenti e progressi',
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                ),
                _buildDivider(),
                _buildToggleTile(
                  icon: Icons.mail_outline,
                  title: 'Email Marketing',
                  subtitle: 'Promozioni e novità',
                  value: _marketingEnabled,
                  onChanged: (val) => setState(() => _marketingEnabled = val),
                ),
                _buildDivider(),
                _buildToggleTile(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  subtitle: 'Aiutaci a migliorare l\'app',
                  value: _analyticsEnabled,
                  onChanged: (val) => setState(() => _analyticsEnabled = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Legal Documents
          CleanSectionHeader(title: 'Documenti Legali'),
          const SizedBox(height: 12),

          CleanCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildNavigationTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                _buildDivider(),
                _buildNavigationTile(
                  icon: Icons.description_outlined,
                  title: 'Termini di Servizio',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Data Rights (GDPR)
          CleanSectionHeader(title: 'I Tuoi Diritti GDPR'),
          const SizedBox(height: 12),

          CleanCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.download_outlined,
                  title: 'Esporta i Miei Dati',
                  subtitle: 'Scarica tutti i tuoi dati in formato JSON',
                  color: CleanTheme.accentBlue,
                  isLoading: _isExporting,
                  onTap: _handleExportData,
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Elimina Account',
                  subtitle: 'Cancella permanentemente i tuoi dati',
                  color: CleanTheme.accentRed,
                  isLoading: _isDeleting,
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact
          CleanCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: CleanTheme.accentGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hai domande sulla privacy?',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Contattaci a: privacy@fitgenius.app',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CleanTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CleanTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: CleanTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: CleanTheme.textSecondary),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: CleanTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CleanTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: CleanTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: CleanTheme.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: CleanTheme.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: color),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 12, color: CleanTheme.textSecondary),
      ),
      trailing: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(Icons.chevron_right, color: color),
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: CleanTheme.borderSecondary,
      indent: 16,
      endIndent: 16,
    );
  }

  Future<void> _handleExportData() async {
    setState(() => _isExporting = true);

    try {
      // TODO: Call backend API to export data
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'I tuoi dati verranno inviati via email entro 24 ore.',
            ),
            backgroundColor: CleanTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'esportazione: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questa azione è irreversibile!',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Eliminando il tuo account:\n'
              '• Tutti i tuoi dati verranno cancellati\n'
              '• Perderai l\'accesso ai piani di allenamento\n'
              '• Gli abbonamenti attivi verranno annullati',
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDeleteAccount();
            },
            child: Text(
              'Elimina Definitivamente',
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

  Future<void> _handleDeleteAccount() async {
    setState(() => _isDeleting = true);

    try {
      // TODO: Call backend API to delete account
      await Future.delayed(const Duration(seconds: 2));

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'eliminazione: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}
