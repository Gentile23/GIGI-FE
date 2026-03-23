import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../../../core/utils/validation_utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cambia Password',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Proteggi il tuo account',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Usa una password forte che non utilizzi per altri account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              _buildPasswordField(
                controller: _currentController,
                label: 'Password Attuale',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _newController,
                label: 'Nuova Password',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (val) => ValidationUtils.validatePassword(
                  val,
                  enterPasswordMsg: l10n.enterPassword,
                  tooShortMsg: l10n.passwordTooShort,
                  uppercaseMsg: l10n.passwordRequirementUppercase,
                  numberMsg: l10n.passwordRequirementNumber,
                ),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _confirmController,
                label: 'Conferma Nuova Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (val) {
                  if (val != _newController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),
              CleanButton(
                text: 'Aggiorna Password',
                isLoading: authProvider.isLoading,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: CleanTheme.textSecondary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: CleanTheme.textTertiary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: CleanTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CleanTheme.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.accentRed, width: 1),
        ),
      ),
      validator:
          validator ??
          (val) {
            if (val == null || val.isEmpty) return 'Campo obbligatorio';
            if (val.length < 8) return 'Minimo 8 caratteri';
            return null;
          },
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
        confirmPassword: _confirmController.text,
      );

      if (success) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password aggiornata con successo!'),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Errore nel cambio password'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}
