import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_config.dart';

class ApiClient {
  late final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, clear it
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ========== HTTP Methods ==========

  /// GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// POST Multipart request (File Upload)
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(
            minutes: 5,
          ), // Long timeout for large files
          receiveTimeout: const Duration(
            minutes: 5,
          ), // Wait for backend processing
        ),
      );
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.put(path, data: body);
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data is Map<String, dynamic>
          ? response.data
          : {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Map<String, dynamic> _handleError(DioException e) {
    String message = 'Si è verificato un errore di rete. Riprova.';
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message = 'Il server non risponde. Controlla la tua connessione.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Impossibile connettersi al server. Riprova più tardi.';
    } else if (e.response != null) {
      message = e.response?.data?['message'] ?? 'Errore del server. Riprova.';
    }

    return {'success': false, 'message': message};
  }

  // ========== Token Management ==========

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);

    // Keep backward compatibility for older app versions and migration safety.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: _tokenKey);
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    // One-time migration path from SharedPreferences -> secure storage.
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(key: _tokenKey, value: legacyToken);
      await prefs.remove(_tokenKey);
    }
    return legacyToken;
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
