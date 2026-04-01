import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../data/models/user_model.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient;
  late final AuthService _authService;
  late final UserService _userService;
  // Google Client ID
  static const String _googleClientId =
      '832030535090-sciu23qp4gsg1m1315u8gmmb3dri2ikd.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _googleClientId : null,
    serverClientId: kIsWeb ? null : _googleClientId,
  );

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;
  bool _registrationVerificationRequired = false;
  String? _pendingVerificationEmail;

  AuthProvider(this._apiClient) {
    _authService = AuthService(_apiClient);
    _userService = UserService(_apiClient);
    _checkAuthStatus();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get registrationVerificationRequired =>
      _registrationVerificationRequired;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  Future<void> _checkAuthStatus() async {
    try {
      if (kIsWeb) {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          await _handleGoogleAuth(account);
        }
      }

      _googleSignIn.onCurrentUserChanged.listen((
        GoogleSignInAccount? account,
      ) async {
        if (account != null) {
          await _handleGoogleAuth(account);
        }
      });
    } catch (e) {
      debugPrint('Google Sign In Initialization Error: $e');
    }

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await fetchUser();
    }
    _isInitializing = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    _registrationVerificationRequired = false;
    _pendingVerificationEmail = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
      );

      _isLoading = false;

      if (result['success']) {
        debugPrint('AuthProvider: Login successful. Verification required: ${result['verification_required']}');
        if (result['verification_required'] == true) {
          _registrationVerificationRequired = true;
          _pendingVerificationEmail = result['email'];
          notifyListeners();
          return true;
        }

        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Login failed. Message: ${result['message']}');
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider Register Error: $e');
      _isLoading = false;
      _error = 'Impossibile completare la registrazione. Riprova più tardi.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyRegistrationOtp(String otp) async {
    if (_pendingVerificationEmail == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.verifyRegistrationOtp(
        email: _pendingVerificationEmail!,
        otp: otp,
      );

      _isLoading = false;

      if (result['success']) {
        _user = result['user'];
        _registrationVerificationRequired = false;
        _pendingVerificationEmail = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Errore durante la verifica.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendRegistrationOtp() async {
    if (_pendingVerificationEmail == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.resendRegistrationOtp(
        email: _pendingVerificationEmail!,
      );

      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Errore nell\'invio dell\'OTP.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    _registrationVerificationRequired = false;
    _pendingVerificationEmail = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      _isLoading = false;

      if (result['success']) {
        debugPrint('AuthProvider: Login successful. Verification required: ${result['verification_required']}');
        if (result['verification_required'] == true) {
          _registrationVerificationRequired = true;
          _pendingVerificationEmail = result['email'];
          notifyListeners();
          return true;
        }

        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        debugPrint('AuthProvider: Login failed. Message: ${result['message']}');
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider Login Error: $e');
      _isLoading = false;
      _error =
          'Impossibile effettuare l\'accesso. Controlla la tua connessione.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        return false;
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser != null) {
        return await _handleGoogleAuth(googleUser);
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthProvider Google Sign In Error: $e');
      _isLoading = false;
      _error = 'Accesso con Google non riuscito.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _handleGoogleAuth(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('_handleGoogleAuth called');

      _isLoading = true;
      notifyListeners();

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Google access token mancante');
      }

      final result = await _authService.socialLogin(
        provider: 'google',
        token: accessToken,
        email: googleUser.email,
        name: googleUser.displayName ?? '',
      );
      debugPrint(
        'AuthService social login completed. success=${result['success'] == true}',
      );

      _isLoading = false;

      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider Handle Google Auth Error: $e');
      _isLoading = false;
      _error = 'Errore durante l\'autenticazione con Google.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String email = credential.email ?? '';
      String? name;
      if (credential.givenName != null) {
        name = '${credential.givenName} ${credential.familyName}';
      }
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token mancante');
      }

      final result = await _authService.socialLogin(
        provider: 'apple',
        token: identityToken,
        email: email,
        name: name,
      );

      _isLoading = false;

      if (result['success']) {
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider Apple Sign In Error: $e');
      _isLoading = false;
      _error = 'Accesso con Apple non riuscito.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Error during auth service logout: $e');
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error during Google sign out: $e');
    }

    _user = null;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    try {
      final result = await _userService.getUser();
      if (result['success']) {
        _user = result['user'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? dateOfBirth,
    double? height,
    double? weight,
    String? bodyShape,
    String? goal,
    List<String>? goals,
    String? level,
    int? weeklyFrequency,
    String? location,
    List<String>? equipment,
    List<String>? limitations,
    List<Map<String, dynamic>>? detailedInjuries,
    String? trainingSplit,
    int? sessionDuration,
    String? cardioPreference,
    String? mobilityPreference,
    String? workoutType,
    List<String>? specificMachines,
    String? bodyweightType,
    List<String>? bodyweightEquipment,
    String? trainingHistory,
    List<String>? preferredDays,
    String? timePreference,
    int? sleepHours,
    String? recoveryCapacity,
    String? nutritionApproach,
    String? bodyFatPercentage,
    String? additionalNotes,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _userService.updateProfile(
        name: name,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        weight: weight,
        bodyShape: bodyShape,
        goal: goal,
        goals: goals,
        level: level,
        weeklyFrequency: weeklyFrequency,
        location: location,
        equipment: equipment,
        limitations: limitations,
        detailedInjuries: detailedInjuries,
        trainingSplit: trainingSplit,
        sessionDuration: sessionDuration,
        cardioPreference: cardioPreference,
        mobilityPreference: mobilityPreference,
        workoutType: workoutType,
        specificMachines: specificMachines,
        bodyweightType: bodyweightType,
        bodyweightEquipment: bodyweightEquipment,
        trainingHistory: trainingHistory,
        preferredDays: preferredDays,
        timePreference: timePreference,
        sleepHours: sleepHours,
        recoveryCapacity: recoveryCapacity,
        nutritionApproach: nutritionApproach,
        bodyFatPercentage: bodyFatPercentage,
        additionalNotes: additionalNotes,
      );

      _isLoading = false;

      if (result['success']) {
        final newUser = result['user'] as UserModel;

        if (_user != null &&
            _user!.avatarUrl != null &&
            newUser.avatarUrl != null) {
          final oldUrl = _user!.avatarUrl!;
          final newUrl = newUser.avatarUrl!;

          if (oldUrl.contains('?') &&
              oldUrl.split('?').first == newUrl.split('?').first) {
            _user = newUser.copyWith(avatarUrl: oldUrl);
          } else {
            _user = newUser;
          }
        } else {
          _user = newUser;
        }

        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider UpdateProfile Error: $e');
      _isLoading = false;
      _error = 'Si è verificato un errore durante l\'aggiornamento del profilo';
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(XFile imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.uploadAvatar(imageFile);

      _isLoading = false;

      if (result['success']) {
        if (_user != null) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final avatarUrl = result['avatar_url'];

          if (avatarUrl != null && avatarUrl.toString().isNotEmpty) {
            final separator = avatarUrl.contains('?') ? '&' : '?';
            _user = _user!.copyWith(
              avatarUrl: '$avatarUrl${separator}t=$timestamp',
            );
          } else {
            await fetchUser();
          }
        }
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider UploadAvatar Error: $e');
      _isLoading = false;
      _error = 'Errore durante il caricamento dell\'immagine';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.requestEmailChange(
        newEmail: newEmail,
        currentPassword: currentPassword,
      );
      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Errore durante la richiesta di cambio email.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmailChange(String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.verifyEmailChange(otp);
      _isLoading = false;

      if (result['success']) {
        await fetchUser();
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Errore durante la verifica dell\'email.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } on DioException catch (_) {
      _isLoading = false;
      _error = 'Errore durante il cambio password.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.deleteAccount();
      _isLoading = false;

      if (result['success']) {
        await logout();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (_) {
      _isLoading = false;
      _error = 'Errore durante l\'eliminazione dell\'account.';
      notifyListeners();
      return false;
    }
  }

  void resetRegistrationVerification() {
    _registrationVerificationRequired = false;
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
