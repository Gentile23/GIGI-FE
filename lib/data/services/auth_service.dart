import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

      return {'success': false, 'message': 'Registration failed'};
    } on DioException catch (e) {
      String message = 'Registration failed';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message =
            'Connection timed out. Check your internet connection or server URL.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Cannot connect to server. Check if server is running and accessible at ${ApiConfig.baseUrl}';
      } else if (e.response != null) {
        message =
            e.response?.data['message'] ??
            'Server error: ${e.response?.statusCode}';
      }

      debugPrint('Registration Error: ${e.message}');
      debugPrint('Error Type: ${e.type}');
      debugPrint('Response: ${e.response?.data}');

      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting login for $email');
      final response = await _apiClient.dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      debugPrint('AuthService: Response status: ${response.statusCode}');
      debugPrint('AuthService: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        await _apiClient.saveToken(data['token']);
        debugPrint('AuthService: Token saved, returning success');
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      }

      debugPrint('AuthService: Unexpected status code ${response.statusCode}');
      return {'success': false, 'message': 'Login failed'};
    } on DioException catch (e) {
      String message = 'Login failed';
      debugPrint('AuthService: DioException caught');
      debugPrint('AuthService: Error type: ${e.type}');
      debugPrint('AuthService: Error message: ${e.message}');
      debugPrint('AuthService: Response status: ${e.response?.statusCode}');
      debugPrint('AuthService: Response data: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message =
            'Connection timed out. Check your internet connection or server URL.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Cannot connect to server. Check if server is running and accessible at ${ApiConfig.baseUrl}';
      } else if (e.response != null) {
        message = e.response?.data['message'] ?? 'Invalid credentials';
      }

      debugPrint('AuthService: Returning error: $message');
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

      return {'success': false, 'message': 'Social login failed'};
    } on DioException catch (e) {
      String message = 'Social login failed';
      if (e.response != null) {
        message = e.response?.data['message'] ?? 'Social login error';
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
