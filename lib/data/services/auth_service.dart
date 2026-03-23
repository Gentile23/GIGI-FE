import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../core/constants/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        
        if (data['requires_verification'] == true) {
          return {
            'success': true,
            'verification_required': true,
            'email': data['email'],
            'message': data['message'],
          };
        }

        if (data['token'] != null) {
          await _apiClient.saveToken(data['token']);
        }
        
        return {
          'success': true,
          'user': data['user'] != null ? UserModel.fromJson(data['user']) : null,
          'token': data['token'],
        };
      }

      return {'success': false, 'message': 'Registrazione non riuscita (Status: ${response.statusCode})'};
    } on DioException catch (e) {
      String message = 'Registrazione non riuscita';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Il server non risponde. Controlla la tua connessione.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossibile connettersi al server. Riprova più tardi.';
      } else if (e.response != null) {
        message = e.response?.data['message'] ?? 'Errore ${e.response?.statusCode}: ${e.response?.data.toString()}';
      }

      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/verify-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          await _apiClient.saveToken(data['token']);
        }
        return {
          'success': true,
          'user': data['user'] != null ? UserModel.fromJson(data['user']) : null,
          'token': data['token'],
        };
      }
      return {'success': false, 'message': 'Verifica fallita'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Errore durante la verifica',
      };
    }
  }

  Future<Map<String, dynamic>> resendRegistrationOtp({
    required String email,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/resend-otp',
        data: {'email': email},
      );

      return {
        'success': response.statusCode == 200,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Errore durante l\'invio dell\'OTP',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['requires_verification'] == true) {
          return {
            'success': true,
            'verification_required': true,
            'email': data['email'],
            'message': data['message'],
          };
        }

        if (data['token'] != null) {
          await _apiClient.saveToken(data['token']);
        }

        return {
          'success': true,
          'user': data['user'] != null ? UserModel.fromJson(data['user']) : null,
          'token': data['token'],
        };
      }

      return {'success': false, 'message': 'Accesso non riuscito'};
    } on DioException catch (e) {
      String message = 'Accesso non riuscito';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Il server non risponde. Controlla la tua connessione.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossibile connettersi al server. Riprova più tardi.';
      } else if (e.response != null) {
        message = e.response?.data['message'] ?? 'Email o password non corretti';
      }

      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> socialLogin({
    required String provider, // 'google' or 'apple'
    required String token, // The ID token or implementation-specific ID
    required String email,
    String? name,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.socialLogin,
        data: {
          'provider': provider,
          'token': token,
          'email': email,
          'name': name,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _apiClient.saveToken(data['token']);
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      }

      return {'success': false, 'message': 'Accesso social non riuscito'};
    } on DioException catch (e) {
      String message = 'Accesso social non riuscito';
      if (e.response != null) {
        message = e.response?.data['message'] ?? 'Errore durante l\'accesso social';
      }
      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await _apiClient.dio.post(ApiConfig.logout);
      await _apiClient.clearToken();
      return {'success': true};
    } on DioException catch (e) {
      await _apiClient.clearToken(); // Clear token anyway
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Logout failed',
      };
    }
  }

  Future<bool> isLoggedIn() async {
    return await _apiClient.hasToken();
  }
}
