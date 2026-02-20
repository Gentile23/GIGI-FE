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

  void _onAuthChanged() {
    if (!mounted || _hasNavigated) return;

    final isAuthenticated = _authProvider?.isAuthenticated ?? false;
    final isLoading = _isLoading; // Ensure we use the local state correctly

    if (isAuthenticated && !isLoading) {
      // User just authenticated (likely from Web GSI button)
      debugPrint('AuthScreen: User authenticated, scheduling navigation...');
      _hasNavigated = true;

      // Schedule navigation for next frame to ensure state is fully updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('AuthScreen: Executing navigation logic...');

        final navigator = Navigator.of(context);
        debugPrint('AuthScreen: navigator.canPop() = ${navigator.canPop()}');

        if (widget.onComplete != null) {
          try {
            debugPrint('AuthScreen: Calling onComplete callback...');
            widget.onComplete!.call();
            return;
          } catch (e) {
            debugPrint('AuthScreen: Error calling onComplete: $e');
          }
        }

        // Default behavior: pop back to root where AppNavigator handles the view
        if (navigator.canPop()) {
          debugPrint('AuthScreen: Popping until first route...');
          navigator.popUntil((route) => route.isFirst);
        } else {
          debugPrint('AuthScreen: Cannot pop, pushing replacement named /...');
          // On Web, if we can't pop, we might be the only route.
          // Pushing '/' ensures the root navigator rebuilds and AppNavigator
          // picks up the authenticated state.
          navigator.pushReplacementNamed('/');
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove listener using stored reference (safe for dispose)
    _authProvider?.removeListener(_onAuthChanged);

    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  bool get _allConsentsAccepted =>
      _acceptedPrivacyPolicy && _acceptedTerms && _acceptedHealthData;

  @override
  Widget build(BuildContext context) {
    // Wait for auth initialization to prevent Google Sign-In plugin errors on web
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
            // 1. Background Motion (Subtle)
            const Positioned.fill(
              child: Opacity(opacity: 0.5, child: BackgroundMotion()),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // 2. Animated Logo (Hero)
                    const Center(
                      child: AnimatedLogo(
                        size: 180,
                        heroTag: 'gigi_logo',
                        enableBreathing: true,
                        enableShimmer: true,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                          _isLogin
                              ? AppLocalizations.of(context)!.welcomeBack
                              : AppLocalizations.of(context)!.createAccount,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 8),

                    Text(
                          _isLogin
                              ? AppLocalizations.of(context)!.loginSubtitle
                              : AppLocalizations.of(context)!.registerSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: CleanTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 100.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // Name field (only for register)
                    if (!_isLogin) ...[
                      _buildTextField(
                            controller: _nameController,
                            label: AppLocalizations.of(context)!.fullName,
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.enterYourName;
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    _buildTextField(
                          controller: _emailController,
                          label: AppLocalizations.of(context)!.email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.enterYourEmail;
                            }
                            if (!value.contains('@')) {
                              return AppLocalizations.of(
                                context,
                              )!.enterValidEmail;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: _isLogin ? 200.ms : 300.ms,
                        )
                        .slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 16),

                    // Password field
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
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(
                                context,
                              )!.enterPassword;
                            }
                            if (value.length < 6) {
                              return AppLocalizations.of(
                                context,
                              )!.passwordTooShort;
                            }
                            return null;
                          },
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: _isLogin ? 300.ms : 400.ms,
                        )
                        .slideX(begin: -0.1, end: 0),

                    // Confirm Password field (only for register)
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                            controller: _confirmPasswordController,
                            label: AppLocalizations.of(
                              context,
                            )!.confirmPassword,
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
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.enterConfirmPassword;
                              }
                              if (value != _passwordController.text) {
                                return AppLocalizations.of(
                                  context,
                                )!.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideX(begin: -0.1, end: 0),

                      // Referral Code (Optional)
                      const SizedBox(height: 16),
                      _buildTextField(
                            controller: _referralCodeController,
                            label: 'Codice Referral (Opzionale)',
                            icon: Icons.confirmation_number_outlined,
                            validator: (value) => null, // Optional
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 600.ms)
                          .slideX(begin: -0.1, end: 0),
                    ],

                    // GDPR Consent checkboxes (only for registration)
                    if (!_isLogin) ...[
                      const SizedBox(height: 24),
                      _buildConsentSection().animate().fadeIn(
                        duration: 400.ms,
                        delay: 700.ms,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Error message
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
                            const Icon(
                              Icons.error_outline,
                              color: CleanTheme.accentRed,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: CleanTheme.accentRed,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: CleanTheme.accentRed,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(),
                      const SizedBox(height: 16),
                    ],

                    // Submit button
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
                        )
                        .animate()
                        .fadeIn(
                          duration: 400.ms,
                          delay: _isLogin ? 400.ms : 800.ms,
                        )
                        .scale(),

                    // Consent reminder for registration
                    if (!_isLogin && !_allConsentsAccepted) ...[
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.acceptAllConsents,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.accentOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: CleanTheme.borderPrimary),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)!.or,
                            style: GoogleFonts.inter(
                              color: CleanTheme.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: CleanTheme.borderPrimary),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: 400.ms,
                      delay: _isLogin ? 500.ms : 900.ms,
                    ),

                    const SizedBox(height: 24),

                    // Google Sign In
                    // Custom styled Google button (localized) for Mobile
                    // Native GSI button for Web
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

                    // Toggle login/register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? AppLocalizations.of(context)!.noAccount
                              : AppLocalizations.of(context)!.haveAccount,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textSecondary,
                          ),
                        ),
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
                            style: GoogleFonts.inter(
                              color: CleanTheme.primaryColor,
                              fontWeight: FontWeight.w600,
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
              ),
            ),

            // Back button (Moved to end of Stack to be on top)
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
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: CleanTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.consentsRequired,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Privacy Policy
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

          // Terms of Service
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

          // Health Data Consent (Art. 9 GDPR)
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
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
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: onLinkTap,
                    child: Text(
                      linkText,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if (required)
                    Text(
                      ' *',
                      style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.textTertiary,
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: CleanTheme.textSecondary),
        prefixIcon: Icon(icon, color: CleanTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: CleanTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: CleanTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CleanTheme.accentRed),
        ),
      ),
      validator: validator,
    );
  }

  // ignore: unused_element
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CleanTheme.textPrimary,
        side: const BorderSide(color: CleanTheme.borderPrimary),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Google Sign-In button styled like Apple (black, premium look)
  Widget _buildGoogleButton({required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" logo
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'G',
                style: GoogleFonts.outfit(
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
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check consents for registration
    if (!_isLogin && !_allConsentsAccepted) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.mustAcceptConsents;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    debugPrint('AuthScreen: Attempting ${_isLogin ? "login" : "register"}...');

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
        referralCode: _referralCodeController.text.isNotEmpty
            ? _referralCodeController.text
            : null,
      );

      if (success && _referralCodeController.text.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Codice referral applicato! Hai 1 mese di Premium gratis! 🎉',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: CleanTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    debugPrint(
      'AuthScreen: Auth result: success=$success, error=${authProvider.error}',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = _translateError(authProvider.error);
          debugPrint('AuthScreen: Error message set to: $_errorMessage');
        }
      });

      if (success) {
        debugPrint('AuthScreen: Login/Register successful, navigating...');
        _hasNavigated = true;

        if (widget.onComplete != null) {
          debugPrint('AuthScreen: Calling onComplete callback');
          widget.onComplete!.call();
        } else {
          // Navigate to home when no onComplete is provided
          debugPrint('AuthScreen: No onComplete, navigating to root...');
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
    if (error == null) {
      return _isLogin
          ? 'Credenziali non valide. Controlla email e password.'
          : 'Registrazione fallita. Riprova più tardi.';
    }

    // Translate common error messages to Italian
    final lowerError = error.toLowerCase();

    if (lowerError.contains('invalid credentials') ||
        lowerError.contains('unauthorized')) {
      return 'Credenziali non valide. Controlla email e password.';
    }
    if (lowerError.contains('email already') ||
        lowerError.contains('email has already')) {
      return 'Questa email è già registrata. Prova ad accedere.';
    }
    if (lowerError.contains('connection') ||
        lowerError.contains('connect to server')) {
      return 'Impossibile connettersi al server. Controlla la connessione internet.';
    }
    if (lowerError.contains('timeout')) {
      return 'Connessione scaduta. Riprova più tardi.';
    }
    if (lowerError.contains('password') && lowerError.contains('short')) {
      return 'La password è troppo corta. Usa almeno 6 caratteri.';
    }
    if (lowerError.contains('user not found')) {
      return 'Utente non trovato. Verifica l\'email inserita.';
    }
    if (lowerError.contains('too many')) {
      return 'Troppi tentativi. Riprova tra qualche minuto.';
    }

    // Return the original error if no translation found
    return error;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success && authProvider.error != null) {
          _errorMessage = _translateError(authProvider.error);
        }
      });

      if (success) {
        widget.onComplete?.call();
      }
    }
  }
}
