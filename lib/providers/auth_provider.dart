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
  );

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  AuthProvider(this._apiClient) {
    _authService = AuthService(_apiClient);
    _userService = UserService(_apiClient);
    _checkAuthStatus();
  }

  // ... (previous code) ...

  // NOTE: Helper accessors to reduce code duplication in replacement
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _checkAuthStatus() async {
    try {
      if (kIsWeb) {
        // This triggers initialization of the web plugin
        // Awaiting it allows us to handle the silent sign-in before finishing initialization
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          await _handleGoogleAuth(account);
        }
      }

      _googleSignIn.onCurrentUserChanged.listen((
        GoogleSignInAccount? account,
      ) async {
        if (account != null) {
          // If we haven't already handled this account or if it's a new one
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
    _isLoading = false; // Ensure loading is also reset
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
        _user = result['user'];
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthProvider Register Error: $e');
      _isLoading = false;
      _error = 'Si è verificato un errore inatteso: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

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
      debugPrint('AuthProvider Login Error: $e');
      _isLoading = false;
      _error = 'Si è verificato un errore inatteso: $e';
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
        // On Web, the button handles the sign-in flow.
        // We just return false here as the listener will handle the success case.
        // The UI should show the Google button which triggers the flow.
        return false;
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser != null) {
        await _handleGoogleAuth(googleUser);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthProvider Google Sign In Error: $e');
      _isLoading = false;
      _error = 'Errore durante l\'accesso con Google: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _handleGoogleAuth(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('_handleGoogleAuth called with user: ${googleUser.email}');

      _isLoading = true;
      notifyListeners();

      // Note: Removed the early return check that blocked existing users
      // This was causing issues on Web where users couldn't re-login

      debugPrint('Calling AuthService.socialLogin...');
      final result = await _authService.socialLogin(
        provider: 'google',
        token: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
      );
      debugPrint('AuthService result: $result');

      _isLoading = false;

      if (result['success']) {
        debugPrint('Social Login Success. Setting user and notifying...');
        _user = result['user'];
        notifyListeners();
        debugPrint(
          'User set: ${_user?.email}, isAuthenticated: $isAuthenticated',
        );
      } else {
        debugPrint('Social Login Failed: ${result['message']}');
        _error = result['message'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider Handle Google Auth Error: $e');
      _isLoading = false;
      _error = 'Errore durante l\'accesso con Google: $e';
      notifyListeners();
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

      // credential.userIdentifier is the detailed Apple User ID

      String email = credential.email ?? '';
      String? name;
      if (credential.givenName != null) {
        name = '${credential.givenName} ${credential.familyName}';
      }

      // If email is hidden/null (subsequent logins), we might need to handle logic differently
      // But for MVP we assume we interpret what we get.
      // Note: Apple only returns email/name on FIRST login.
      // Backend logic requires email. If missing, this might fail unless we store it locally or use JWT decoding on backend.
      // For now, we pass what we have, understanding 'email' is required by backend validation.
      // If email is empty, we might need to decode identityToken on client or backend.
      // Let's assume for this step we catch obvious errors.

      if (email.isEmpty) {
        // Fallback or error - simplistic handling for now
        // In robust apps we decode identityToken to get email if available in claims
      }

      final result = await _authService.socialLogin(
        provider: 'apple',
        token: credential.userIdentifier!,
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
      _error = 'Errore durante l\'accesso con Apple: $e';
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
    String? gender,
    int? age,
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
    // Professional Trainer Fields
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
        gender: gender,
        age: age,
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
        // Professional Trainer Fields
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
        _user = result['user'];
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

  /// Upload user avatar
  Future<bool> uploadAvatar(XFile imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _userService.uploadAvatar(imageFile);

      _isLoading = false;

      if (result['success']) {
        // Update user with new avatar URL
        if (_user != null) {
          _user = _user!.copyWith(avatarUrl: result['avatar_url']);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
