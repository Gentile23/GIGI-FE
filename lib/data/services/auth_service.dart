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

      if (response.statusCode == 201) {
        final data = response.data;
        await _apiClient.saveToken(data['token']);
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      }

      return {'success': false, 'message': 'Registrazione non riuscita'};
    } on DioException catch (e) {
      String message = 'Registrazione non riuscita';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'Il server non risponde. Controlla la tua connessione.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossibile connettersi al server. Riprova più tardi.';
      } else if (e.response != null) {
        message = e.response?.data['message'] ?? 'Errore durante la registrazione';
      }

      return {'success': false, 'message': message};
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
        await _apiClient.saveToken(data['token']);
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
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
