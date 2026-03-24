import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _obscurePassword = true;
  String? _pendingEmail;
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _resendCooldownTimer?.cancel();
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
          'Aggiorna Email',
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
      body: RefreshIndicator(
        onRefresh: () => authProvider.fetchUser(),
        color: CleanTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Icon & Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: CleanTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _otpSent
                    ? 'Verifica la tua Email'
                    : 'Cambia il tuo indirizzo Email',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Inserisci il codice a 6 cifre inviato a:\n$_pendingEmail'
                    : 'Riceverai un codice di sicurezza per confermare la tua nuova email.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              if (!_otpSent)
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        label: l10n.email,
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.enterYourEmail;
                          }
                          if (!value.contains('@')) {
                            return l10n.enterValidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password Attuale',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: CleanTheme.textTertiary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci la password attuale';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CleanButton(
                        text: 'Richiedi Codice',
                        width: double.infinity,
                        isLoading: authProvider.isLoading,
                        onPressed: _handleRequestOtp,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        counterText: '',
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    CleanButton(
                      text: 'Verifica e Salva',
                      width: double.infinity,
                      isLoading: authProvider.isLoading,
                      onPressed: _handleVerifyOtp,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: (authProvider.isLoading || _resendCooldownSeconds > 0) ? null : () async {
                        final success = await authProvider.requestEmailChange(
                          newEmail: _pendingEmail!,
                          currentPassword: _passwordController.text,
                        );
                        if (success) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nuovo codice inviato!'))
                          );
                          setState(() => _resendCooldownSeconds = 60);
                          _resendCooldownTimer?.cancel();
                          _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                            if (!mounted) {
                              timer.cancel();
                              return;
                            }
                            setState(() {
                              if (_resendCooldownSeconds > 0) {
                                _resendCooldownSeconds--;
                              } else {
                                timer.cancel();
                              }
                            });
                          });
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authProvider.error ?? 'Errore nell\'invio'),
                              backgroundColor: CleanTheme.accentRed,
                            ),
                          );
                        }
                      },
                      child: Text(
                        _resendCooldownSeconds > 0 
                            ? 'Attendi $_resendCooldownSeconds s per reinviare' 
                            : 'Non hai ricevuto il codice? Reinvia',
                        style: GoogleFonts.inter(
                          color: _resendCooldownSeconds > 0 ? CleanTheme.textTertiary : CleanTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _resendCooldownTimer?.cancel();
                        setState(() {
                          _otpSent = false;
                          _resendCooldownSeconds = 0;
                        });
                      },
                      child: Text(
                        'Cambia Indirizzo Email',
                        style: GoogleFonts.inter(
                          color: CleanTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        prefixIcon: Icon(icon, color: CleanTheme.textSecondary, size: 20),
        suffixIcon: suffixIcon,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _handleRequestOtp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final newEmail = _emailController.text.trim();

      if (newEmail == authProvider.user?.email) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserisci un\'email diversa da quella attuale'),
          ),
        );
        return;
      }

      final success = await authProvider.requestEmailChange(
        newEmail: newEmail,
        currentPassword: _passwordController.text,
      );
      if (success) {
        if (!mounted) return;
        setState(() {
          _otpSent = true;
          _pendingEmail = newEmail;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Errore nella richiesta'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il codice a 6 cifre')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyEmailChange(_otpController.text);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email aggiornata con successo!'),
          backgroundColor: CleanTheme.accentGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Codice non valido'),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }
}
