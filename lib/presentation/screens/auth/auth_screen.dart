import 'dart:async';
import 'package:gigi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/background_motion.dart';
import '../../widgets/animations/animated_logo.dart';

import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart';
import '../../../core/utils/validation_utils.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool initialIsLogin;

  const AuthScreen({super.key, this.onComplete, this.initialIsLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // GDPR Consent checkboxes
  bool _acceptedPrivacyPolicy = false;
  bool _acceptedTerms = false;
  bool _acceptedHealthData = false;

  // Store AuthProvider reference for safe disposal
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;

    // Listen for auth changes (needed for Web GSI button flow)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider?.addListener(_onAuthChanged);
    });
  }

  // Flag to prevent multiple navigation attempts
  bool _hasNavigated = false;

  // OTP Resend Cooldown
  Timer? _resendCooldownTimer;
  int _resendCooldownSeconds = 0;

  void _onAuthChanged() {
    if (!mounted || _hasNavigated) return;

    final isAuthenticated = _authProvider?.isAuthenticated ?? false;
    final isLoading = _isLoading; 

    if (isAuthenticated && !isLoading) {
      _hasNavigated = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final navigator = Navigator.of(context);

        if (widget.onComplete != null) {
          try {
            widget.onComplete!.call();
            return;
          } catch (e) {
            debugPrint('AuthScreen: Error calling onComplete: $e');
          }
        }

        if (navigator.canPop()) {
          navigator.popUntil((route) => route.isFirst);
        } else {
          navigator.pushReplacementNamed('/');
        }
      });
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _resendCooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _allConsentsAccepted =>
      _acceptedPrivacyPolicy && _acceptedTerms && _acceptedHealthData;

  @override
  Widget build(BuildContext context) {
    final isInitializing = context.select<AuthProvider, bool>(
      (p) => p.isInitializing,
    );

    if (isInitializing) {
      return const Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: Opacity(opacity: 0.3, child: BackgroundMotion()),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.registrationVerificationRequired) {
                    return _buildOtpVerificationUI(authProvider);
                  }
                  
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        const Center(
                          child: AnimatedLogo(
                            size: 160,
                            heroTag: 'gigi_logo',
                            enableBreathing: true,
                            enableShimmer: true,
                          ),
                        ),

                        const SizedBox(height: 32),

                        Text(
                          _isLogin
                              ? AppLocalizations.of(context)!.welcomeBack
                              : AppLocalizations.of(context)!.createAccount,
                          style: GoogleFonts.lexend(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: CleanTheme.textPrimary,
                            letterSpacing: -1.0,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 12),

                        Text(
                          _isLogin
                              ? AppLocalizations.of(context)!.loginSubtitle
                              : AppLocalizations.of(context)!.registerSubtitle,
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            color: CleanTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 40),

                        CleanCard(
                          borderRadius: 32,
                          enableGlass: true,
                          hasShadow: true,
                          backgroundColor: CleanTheme.surfaceColor.withValues(alpha: 0.8),
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isLogin) ...[
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
                                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1, end: 0),
                                const SizedBox(height: 16),
                              ],

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
                              ).animate().fadeIn(
                                duration: 400.ms,
                                delay: _isLogin ? 200.ms : 300.ms,
                              ).slideX(begin: -0.1, end: 0),

                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _passwordController,
                                label: AppLocalizations.of(context)!.password,
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: CleanTheme.textTertiary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                 validator: (value) {
                                  if (_isLogin) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!.enterPassword;
                                    }
                                    return null;
                                  }
                                  return ValidationUtils.validatePassword(
                                    value,
                                    enterPasswordMsg: AppLocalizations.of(context)!.enterPassword,
                                    tooShortMsg: AppLocalizations.of(context)!.passwordTooShort,
                                    uppercaseMsg: AppLocalizations.of(context)!.passwordRequirementUppercase,
                                    numberMsg: AppLocalizations.of(context)!.passwordRequirementNumber,
                                  );
                                },
                              ).animate().fadeIn(
                                duration: 400.ms,
                                delay: _isLogin ? 300.ms : 400.ms,
                              ).slideX(begin: -0.1, end: 0),

                              if (!_isLogin) ...[
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  label: AppLocalizations.of(context)!.confirmPassword,
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: CleanTheme.textTertiary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppLocalizations.of(context)!.enterConfirmPassword;
                                    }
                                    if (value != _passwordController.text) {
                                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                                    }
                                    return null;
                                  },
                                ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideX(begin: -0.1, end: 0),

                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _referralCodeController,
                                  label: 'Codice Referral (Opzionale)',
                                  icon: Icons.confirmation_number_outlined,
                                  validator: (value) => null,
                                ).animate().fadeIn(duration: 400.ms, delay: 600.ms).slideX(begin: -0.1, end: 0),
                              ],

                              if (!_isLogin) ...[
                                const SizedBox(height: 24),
                                _buildConsentSection().animate().fadeIn(duration: 400.ms, delay: 700.ms),
                              ],

                              const SizedBox(height: 32),

                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CleanTheme.accentRed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: CleanTheme.accentRed.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: CleanTheme.accentRed, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.lexend(
                                            color: CleanTheme.accentRed,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: CleanTheme.accentRed, size: 20),
                                        onPressed: () => setState(() => _errorMessage = null),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().shake(),
                                const SizedBox(height: 16),
                              ],

                              CleanButton(
                                text: _isLogin
                                    ? AppLocalizations.of(context)!.login
                                    : AppLocalizations.of(context)!.register,
                                onPressed: _isLoading
                                    ? null
                                    : (_isLogin || _allConsentsAccepted)
                                    ? _handleSubmit
                                    : null,
                                width: double.infinity,
                                isPrimary: true,
                              ).animate().fadeIn(
                                duration: 400.ms,
                                delay: _isLogin ? 400.ms : 800.ms,
                              ).scale(),

                              if (!_isLogin && !_allConsentsAccepted) ...[
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.acceptAllConsents,
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: CleanTheme.accentOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Expanded(child: Divider(color: CleanTheme.borderSecondary)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppLocalizations.of(context)!.or,
                                style: GoogleFonts.lexend(
                                  color: CleanTheme.textTertiary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: CleanTheme.borderSecondary)),
                          ],
                        ).animate().fadeIn(
                          duration: 400.ms,
                          delay: _isLogin ? 500.ms : 900.ms,
                        ),

                        const SizedBox(height: 24),

                        if (kIsWeb)
                          Center(child: getGoogleSignInButton())
                        else
                          _buildGoogleButton(
                            onPressed: _handleGoogleSignIn,
                          ).animate().fadeIn(
                            duration: 400.ms,
                            delay: _isLogin ? 600.ms : 1000.ms,
                          ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? AppLocalizations.of(context)!.noAccount
                                  : AppLocalizations.of(context)!.haveAccount,
                              style: GoogleFonts.lexend(
                                color: CleanTheme.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isLogin
                                    ? AppLocalizations.of(context)!.register
                                    : AppLocalizations.of(context)!.login,
                                style: GoogleFonts.lexend(
                                  color: CleanTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(
                          duration: 400.ms,
                          delay: _isLogin ? 700.ms : 1100.ms,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (Navigator.canPop(context))
              PositionedDirectional(
                start: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: CleanTheme.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: CleanTheme.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.consentsRequired,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConsentCheckbox(
            value: _acceptedPrivacyPolicy,
            onChanged: (val) => setState(() => _acceptedPrivacyPolicy = val!),
            label: AppLocalizations.of(context)!.acceptPrivacyPolicy,
            linkText: AppLocalizations.of(context)!.privacyPolicy,
            onLinkTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            required: true,
          ),
          const SizedBox(height: 12),
          _buildConsentCheckbox(
            value: _acceptedTerms,
            onChanged: (val) => setState(() => _acceptedTerms = val!),
            label: AppLocalizations.of(context)!.acceptTerms,
            linkText: AppLocalizations.of(context)!.termsOfService,
            onLinkTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
            ),
            required: true,
          ),
          const SizedBox(height: 12),
          _buildConsentCheckbox(
            value: _acceptedHealthData,
            onChanged: (val) => setState(() => _acceptedHealthData = val!),
            label: AppLocalizations.of(context)!.acceptHealthData,
            linkText: AppLocalizations.of(context)!.healthDataLink,
            sublabel: AppLocalizations.of(context)!.healthDataDescription,
            onLinkTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            required: true,
            isHealthData: true,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String linkText,
    required VoidCallback onLinkTap,
    String? sublabel,
    bool required = false,
    bool isHealthData = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: CleanTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                children: [
                  Text(
                    label,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: CleanTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: onLinkTap,
                    child: Text(
                      linkText,
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (required)
                    Text(
                      ' *',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        color: CleanTheme.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (sublabel != null) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: CleanTheme.textTertiary,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.lexend(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textSecondary.withValues(alpha: 0.8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.lexend(
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: CleanTheme.textSecondary.withValues(alpha: 0.6),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: CleanTheme.textPrimary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: CleanTheme.textPrimary.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: CleanTheme.textPrimary.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: CleanTheme.textPrimary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: CleanTheme.accentRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildGoogleButton({required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 2,
        shadowColor: Colors.black12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Center(
              child: Text(
                'G',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.continueWithGoogle,
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (!_isLogin && !_allConsentsAccepted) {
      setState(() => _errorMessage = AppLocalizations.of(context)?.mustAcceptConsents ?? 'Devi accettare tutti i consensi per registrarti.');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        referralCode: _referralCodeController.text.isNotEmpty ? _referralCodeController.text : null,
      );

      if (success && _referralCodeController.text.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Codice referral applicato! Hai 1 mese di Premium gratis! 🎉',
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600),
            ),
            backgroundColor: CleanTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = _translateError(authProvider.error);
        }
      });

      if (success) {
        if (authProvider.registrationVerificationRequired) return;
        _hasNavigated = true;
        if (widget.onComplete != null) {
          widget.onComplete!.call();
        } else {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.popUntil((route) => route.isFirst);
          } else {
            navigator.pushReplacementNamed('/');
          }
        }
      }
    }
  }

  String _translateError(String? error) {
    if (error == null || error.isEmpty) {
      return _isLogin
          ? 'Accesso fallito. Controlla le tue credenziali.'
          : 'Registrazione non riuscita. Riprova più tardi.';
    }

    final lowerError = error.toLowerCase();
    if (lowerError.contains('invalid credentials') || lowerError.contains('unauthorized') || lowerError.contains('401')) {
      return 'Email o password non corretti. Riprova.';
    }
    if (lowerError.contains('email already') || lowerError.contains('taken') || lowerError.contains('already registered')) {
      return 'Questa email è già in uso. Prova ad accedere o usa un\'altra email.';
    }
    if (lowerError.contains('connection') || lowerError.contains('network') || lowerError.contains('socketexception')) {
      return 'Problema di connessione. Controlla la tua rete.';
    }
    if (lowerError.contains('timeout')) {
      return 'Il server ha impiegato troppo tempo a rispondere. Riprova.';
    }
    if (lowerError.contains('password') && lowerError.contains('short')) {
      return 'La password deve contenere almeno 6 caratteri.';
    }
    if (lowerError.contains('user not found')) {
      return 'Non abbiamo trovato un account con questa email.';
    }
    if (lowerError.contains('too many attempts')) {
      return 'Troppi tentativi di accesso. Riprova tra qualche minuto.';
    }
    if (lowerError.contains('server error') || lowerError.contains('500')) {
      return 'C\'è un problema tecnico sui nostri server. Stiamo lavorando per risolverlo.';
    }
    
    // If no specific translation matches, but we have a technical error from AuthService, show it
    return error;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success && authProvider.error != null) {
          _errorMessage = _translateError(authProvider.error);
        }
      });
      if (success) widget.onComplete?.call();
    }
  }

  Widget _buildOtpVerificationUI(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Center(
          child: AnimatedLogo(
            size: 140,
            heroTag: 'gigi_logo_otp',
            enableBreathing: true,
          ),
        ),
        const SizedBox(height: 32),
        
        CleanCard(
          borderRadius: 32,
          enableGlass: true,
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _otpFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verifica Email',
                style: GoogleFonts.lexend(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                  letterSpacing: -1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Abbiamo inviato un codice a\n${authProvider.pendingVerificationEmail}',
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  color: CleanTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              _buildTextField(
                controller: _otpController,
                label: 'Codice di verifica',
                icon: Icons.vpn_key_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Inserisci il codice';
                  if (value.length != 6) return 'Il codice deve essere di 6 cifre';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              if (authProvider.error != null) ...[
                Text(
                  _translateError(authProvider.error),
                  style: GoogleFonts.lexend(
                    color: CleanTheme.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              
              CleanButton(
                text: 'Verifica',
                onPressed: _isLoading ? null : () async {
                  final otpState = _otpFormKey.currentState;
                  if (otpState != null && otpState.validate()) {
                    setState(() => _isLoading = true);
                    final success = await authProvider.verifyRegistrationOtp(_otpController.text);
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                    if (success) {
                      if (!mounted) return;
                      _hasNavigated = true;
                      if (widget.onComplete != null) {
                        widget.onComplete!.call();
                      } else {
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.popUntil((route) => route.isFirst);
                        } else {
                          navigator.pushReplacementNamed('/');
                        }
                      }
                    }
                  }
                },
                width: double.infinity,
                isPrimary: true,
              ),
              
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: (_isLoading || _resendCooldownSeconds > 0) ? null : () async {
                  final success = await authProvider.resendRegistrationOtp();
                  if (success) {
                    if (!mounted) return;
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
                  }
                },
                child: Text(
                  _resendCooldownSeconds > 0 
                      ? 'Attendi $_resendCooldownSeconds s per reinviare' 
                      : 'Non hai ricevuto il codice? Reinvia',
                  style: GoogleFonts.lexend(
                    color: _resendCooldownSeconds > 0 ? CleanTheme.textTertiary : CleanTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () {
                  authProvider.resetRegistrationVerification();
                  setState(() {
                    _isLogin = true;
                    _otpController.clear();
                  });
                },
                child: Text(
                  'Torna al Login',
                  style: GoogleFonts.lexend(
                    color: CleanTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
}
