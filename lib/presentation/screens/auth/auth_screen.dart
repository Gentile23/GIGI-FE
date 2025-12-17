import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const AuthScreen({super.key, this.onComplete});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // GDPR Consent checkboxes
  bool _acceptedPrivacyPolicy = false;
  bool _acceptedTerms = false;
  bool _acceptedHealthData = false;

  // Animation controller for logo
  late AnimationController _logoAnimationController;
  late Animation<double> _logoOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeIn),
    );

    // Start animation
    _logoAnimationController.forward();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo GIGI with fade-in animation
                Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacityAnimation.value,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 200,
                      height: 80,
                      child: Image.asset(
                        'assets/images/gigi_new_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'GIGI',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  _isLogin ? 'Bentornato!' : 'Crea Account',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? 'Accedi per continuare il tuo percorso fitness'
                      : 'Inizia oggi il tuo percorso fitness',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: CleanTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Name field (only for register)
                if (!_isLogin) ...[
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
                ],

                // Email field
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

                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
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
                      return 'Inserisci la password';
                    }
                    if (value.length < 6) {
                      return 'La password deve essere di almeno 6 caratteri';
                    }
                    return null;
                  },
                ),

                // GDPR Consent checkboxes (only for registration)
                if (!_isLogin) ...[
                  const SizedBox(height: 24),
                  _buildConsentSection(),
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
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit button
                CleanButton(
                  text: _isLogin ? 'Accedi' : 'Registrati',
                  onPressed: _isLoading
                      ? null
                      : (_isLogin || _allConsentsAccepted)
                      ? _handleSubmit
                      : null,
                  width: double.infinity,
                ),

                // Consent reminder for registration
                if (!_isLogin && !_allConsentsAccepted) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Accetta tutti i consensi per procedere',
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
                        'oppure',
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
                ),

                const SizedBox(height: 24),

                // Google Sign In
                if (kIsWeb)
                  // Use the official Google Sign-In button on Web
                  Center(
                    child: (GoogleSignInPlatform.instance as GoogleSignInPlugin)
                        .renderButton(),
                  )
                else
                  _buildSocialButton(
                    icon: Icons.g_mobiledata,
                    label: 'Continua con Google',
                    onPressed: _handleGoogleSignIn,
                  ),

                const SizedBox(height: 12),

                // Apple Sign In
                _buildSocialButton(
                  icon: Icons.apple,
                  label: 'Continua con Apple',
                  onPressed: _handleAppleSignIn,
                ),

                const SizedBox(height: 32),

                // Toggle login/register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? 'Non hai un account? '
                          : 'Hai già un account? ',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _isLogin ? 'Registrati' : 'Accedi',
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
                'Consensi richiesti',
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
            label: 'Ho letto e accetto la ',
            linkText: 'Privacy Policy',
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
            label: 'Accetto i ',
            linkText: 'Termini di Servizio',
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
            label: 'Acconsento al trattamento dei miei ',
            linkText: 'dati sulla salute',
            sublabel:
                '(peso, altezza, infortuni) per personalizzare '
                'i piani di allenamento',
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
            activeColor: isHealthData
                ? CleanTheme.accentPurple
                : CleanTheme.primaryColor,
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
                        color: isHealthData
                            ? CleanTheme.accentPurple
                            : CleanTheme.primaryColor,
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
        _errorMessage = 'Devi accettare tutti i consensi per registrarti.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (!success) {
          _errorMessage = _translateError(authProvider.error);
        }
      });

      if (success) {
        widget.onComplete?.call();
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

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();

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
