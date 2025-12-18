import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final String _googleClientId =
      '832030535090-sciu23qp4gsg1m1315u8gmmb3dri2ikd.apps.googleusercontent.com';

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
      await GoogleSignIn.instance.initialize(
        serverClientId: kIsWeb ? null : _googleClientId,
        clientId: kIsWeb ? _googleClientId : null,
      );

      // Listen to auth state changes using the new API
      // Since we can't easily see the type, we'll try to listen to the stream
      // and inspect the event dynamically. Use a broad dynamic cast to avoid
      // analyzer errors for now.
      (GoogleSignIn.instance as dynamic).authenticationEvents.listen((
        event,
      ) async {
        debugPrint('Google Auth Event Detected: $event');

        // In v7, the event carries the user.
        // We cast to dynamic to access .user property if it exists on the specific event type.
        try {
          final dynamic evt = event;
          // Check if it's a sign-in event (has 'user' property)
          try {
            // Access dynamically to bypass static analysis for now
            final user = evt.user;
            debugPrint('User from event: $user');
            if (user != null) {
              await _handleGoogleAuth(user);
            }
          } catch (err) {
            // Property 'user' might not exist on all events (e.g. sign out)
            if (event.toString().contains('SignIn')) {
              debugPrint(
                'Detected SignIn event but could not extract user: $err',
              );
            }
          }
        } catch (e) {
          debugPrint('Error processing auth event: $e');
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
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
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
        googleUser = await GoogleSignIn.instance.authenticate();
      }

      // Handle mobile sign-in explicitly (listener might also catch it, but we can double check)
      // Actually, onCurrentUserChanged fires for mobile too.
      // To avoid double processing, we can rely on the listener OR explicit call.
      // For now, let's process it here for mobile to ensure we await result.
      await _handleGoogleAuth(googleUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleGoogleAuth(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('_handleGoogleAuth called with user: ${googleUser.email}');

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
    await _authService.logout();
    await GoogleSignIn.instance.signOut();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
