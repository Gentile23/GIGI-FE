// Unit tests for API/Service layer
import 'package:flutter_test/flutter_test.dart';

// Mock API Response class
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.error(String message, {int statusCode = 400}) {
    return ApiResponse(success: false, error: message, statusCode: statusCode);
  }

  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;
  bool get isError => !success || statusCode >= 400;
  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}

// Mock API Endpoint helper
class ApiEndpoints {
  static const String baseUrl = 'https://api.gigi.app/v1';

  static String login() => '$baseUrl/auth/login';
  static String register() => '$baseUrl/auth/register';
  static String logout() => '$baseUrl/auth/logout';
  static String profile() => '$baseUrl/user/profile';
  static String updateProfile() => '$baseUrl/user/profile';
  static String workouts() => '$baseUrl/workouts';
  static String workout(int id) => '$baseUrl/workouts/$id';
  static String exercises() => '$baseUrl/exercises';
  static String exercise(int id) => '$baseUrl/exercises/$id';
  static String workoutLogs() => '$baseUrl/workout-logs';
  static String workoutLog(int id) => '$baseUrl/workout-logs/$id';
  static String nutrition() => '$baseUrl/nutrition';
  static String meals() => '$baseUrl/nutrition/meals';
  static String meal(int id) => '$baseUrl/nutrition/meals/$id';
  static String challenges() => '$baseUrl/challenges';
  static String challenge(int id) => '$baseUrl/challenges/$id';
  static String leaderboard() => '$baseUrl/leaderboard';
  static String activityFeed() => '$baseUrl/social/feed';
  static String kudos(int activityId) => '$baseUrl/social/$activityId/kudos';
  static String generatePlan() => '$baseUrl/ai/generate-plan';
  static String analyzeMeal() => '$baseUrl/ai/analyze-meal';
  static String formCheck() => '$baseUrl/ai/form-check';
}

// Mock Request Validation
class RequestValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\+\-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  static bool isValidHeight(double? height) {
    if (height == null) return false;
    return height >= 50 && height <= 300;
  }

  static bool isValidWeight(double? weight) {
    if (weight == null) return false;
    return weight >= 20 && weight <= 500;
  }

  static bool isValidAge(int? age) {
    if (age == null) return false;
    return age >= 13 && age <= 120;
  }

  static Map<String, String> validateLoginRequest(
    String email,
    String password,
  ) {
    final errors = <String, String>{};
    if (!isValidEmail(email)) errors['email'] = 'Invalid email format';
    if (!isValidPassword(password)) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    return errors;
  }

  static Map<String, String> validateRegistrationRequest({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <String, String>{};
    if (!isValidName(name)) {
      errors['name'] = 'Name must be at least 2 characters';
    }
    if (!isValidEmail(email)) {
      errors['email'] = 'Invalid email format';
    }
    if (!isValidPassword(password)) {
      errors['password'] = 'Password must be at least 6 characters';
    }
    if (password != confirmPassword) {
      errors['confirmPassword'] = 'Passwords do not match';
    }
    return errors;
  }
}

// Mock Rate Limiter
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _requests = [];

  RateLimiter({required this.maxRequests, required this.window});

  bool canMakeRequest() {
    _cleanOldRequests();
    return _requests.length < maxRequests;
  }

  void recordRequest() {
    _requests.add(DateTime.now());
  }

  void _cleanOldRequests() {
    final cutoff = DateTime.now().subtract(window);
    _requests.removeWhere((r) => r.isBefore(cutoff));
  }

  int get remainingRequests => maxRequests - _requests.length;

  Duration get resetTime {
    if (_requests.isEmpty) return Duration.zero;
    final oldest = _requests.reduce((a, b) => a.isBefore(b) ? a : b);
    final resetAt = oldest.add(window);
    return resetAt.difference(DateTime.now());
  }
}

void main() {
  group('ApiResponse Model', () {
    test('Success response creation', () {
      final response = ApiResponse.success({'user_id': 1}, statusCode: 200);

      expect(response.success, true);
      expect(response.data, {'user_id': 1});
      expect(response.statusCode, 200);
      expect(response.isSuccess, true);
      expect(response.isError, false);
    });

    test('Error response creation', () {
      final response = ApiResponse.error(
        'Invalid credentials',
        statusCode: 401,
      );

      expect(response.success, false);
      expect(response.error, 'Invalid credentials');
      expect(response.statusCode, 401);
      expect(response.isSuccess, false);
      expect(response.isError, true);
      expect(response.isUnauthorized, true);
    });

    test('Status code checks', () {
      expect(ApiResponse.error('', statusCode: 401).isUnauthorized, true);
      expect(ApiResponse.error('', statusCode: 404).isNotFound, true);
      expect(ApiResponse.error('', statusCode: 500).isServerError, true);
      expect(ApiResponse.error('', statusCode: 503).isServerError, true);
    });
  });

  group('ApiEndpoints', () {
    test('Base URL is correct', () {
      expect(ApiEndpoints.baseUrl, 'https://api.gigi.app/v1');
    });

    test('Auth endpoints', () {
      expect(ApiEndpoints.login(), 'https://api.gigi.app/v1/auth/login');
      expect(ApiEndpoints.register(), 'https://api.gigi.app/v1/auth/register');
      expect(ApiEndpoints.logout(), 'https://api.gigi.app/v1/auth/logout');
    });

    test('User endpoints', () {
      expect(ApiEndpoints.profile(), 'https://api.gigi.app/v1/user/profile');
    });

    test('Workout endpoints with ID', () {
      expect(ApiEndpoints.workouts(), 'https://api.gigi.app/v1/workouts');
      expect(ApiEndpoints.workout(123), 'https://api.gigi.app/v1/workouts/123');
    });

    test('Exercise endpoints with ID', () {
      expect(ApiEndpoints.exercises(), 'https://api.gigi.app/v1/exercises');
      expect(
        ApiEndpoints.exercise(456),
        'https://api.gigi.app/v1/exercises/456',
      );
    });

    test('Nutrition endpoints', () {
      expect(ApiEndpoints.nutrition(), 'https://api.gigi.app/v1/nutrition');
      expect(ApiEndpoints.meals(), 'https://api.gigi.app/v1/nutrition/meals');
      expect(
        ApiEndpoints.meal(789),
        'https://api.gigi.app/v1/nutrition/meals/789',
      );
    });

    test('Social endpoints', () {
      expect(
        ApiEndpoints.activityFeed(),
        'https://api.gigi.app/v1/social/feed',
      );
      expect(
        ApiEndpoints.kudos(100),
        'https://api.gigi.app/v1/social/100/kudos',
      );
    });

    test('AI endpoints', () {
      expect(
        ApiEndpoints.generatePlan(),
        'https://api.gigi.app/v1/ai/generate-plan',
      );
      expect(
        ApiEndpoints.analyzeMeal(),
        'https://api.gigi.app/v1/ai/analyze-meal',
      );
      expect(ApiEndpoints.formCheck(), 'https://api.gigi.app/v1/ai/form-check');
    });
  });

  group('RequestValidator', () {
    test('Email validation', () {
      expect(RequestValidator.isValidEmail('test@example.com'), true);
      expect(RequestValidator.isValidEmail('user+tag@domain.co.uk'), true);
      expect(RequestValidator.isValidEmail('invalid'), false);
      expect(RequestValidator.isValidEmail(''), false);
    });

    test('Password validation', () {
      expect(RequestValidator.isValidPassword('123456'), true);
      expect(RequestValidator.isValidPassword('password'), true);
      expect(RequestValidator.isValidPassword('12345'), false);
      expect(RequestValidator.isValidPassword(''), false);
    });

    test('Name validation', () {
      expect(RequestValidator.isValidName('Mario'), true);
      expect(RequestValidator.isValidName('M'), false);
      expect(RequestValidator.isValidName(''), false);
      expect(RequestValidator.isValidName('  '), false);
    });

    test('Height validation', () {
      expect(RequestValidator.isValidHeight(180), true);
      expect(RequestValidator.isValidHeight(50), true);
      expect(RequestValidator.isValidHeight(300), true);
      expect(RequestValidator.isValidHeight(49), false);
      expect(RequestValidator.isValidHeight(301), false);
      expect(RequestValidator.isValidHeight(null), false);
    });

    test('Weight validation', () {
      expect(RequestValidator.isValidWeight(75), true);
      expect(RequestValidator.isValidWeight(20), true);
      expect(RequestValidator.isValidWeight(500), true);
      expect(RequestValidator.isValidWeight(19), false);
      expect(RequestValidator.isValidWeight(501), false);
      expect(RequestValidator.isValidWeight(null), false);
    });

    test('Age validation', () {
      expect(RequestValidator.isValidAge(30), true);
      expect(RequestValidator.isValidAge(13), true);
      expect(RequestValidator.isValidAge(120), true);
      expect(RequestValidator.isValidAge(12), false);
      expect(RequestValidator.isValidAge(121), false);
      expect(RequestValidator.isValidAge(null), false);
    });

    test('Login request validation', () {
      final valid = RequestValidator.validateLoginRequest(
        'test@example.com',
        'password123',
      );
      expect(valid, isEmpty);

      final invalidEmail = RequestValidator.validateLoginRequest(
        'invalid',
        'password123',
      );
      expect(invalidEmail.containsKey('email'), true);

      final invalidPassword = RequestValidator.validateLoginRequest(
        'test@example.com',
        '123',
      );
      expect(invalidPassword.containsKey('password'), true);
    });

    test('Registration request validation', () {
      final valid = RequestValidator.validateRegistrationRequest(
        name: 'Mario Rossi',
        email: 'mario@example.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(valid, isEmpty);

      final mismatch = RequestValidator.validateRegistrationRequest(
        name: 'Mario Rossi',
        email: 'mario@example.com',
        password: 'password123',
        confirmPassword: 'different',
      );
      expect(mismatch.containsKey('confirmPassword'), true);
    });
  });

  group('RateLimiter', () {
    test('Allows requests within limit', () {
      final limiter = RateLimiter(
        maxRequests: 5,
        window: const Duration(minutes: 1),
      );

      expect(limiter.canMakeRequest(), true);
      expect(limiter.remainingRequests, 5);
    });

    test('Records requests', () {
      final limiter = RateLimiter(
        maxRequests: 3,
        window: const Duration(minutes: 1),
      );

      limiter.recordRequest();
      expect(limiter.remainingRequests, 2);

      limiter.recordRequest();
      expect(limiter.remainingRequests, 1);

      limiter.recordRequest();
      expect(limiter.remainingRequests, 0);
      expect(limiter.canMakeRequest(), false);
    });

    test('Starts with empty reset time', () {
      final limiter = RateLimiter(
        maxRequests: 5,
        window: const Duration(minutes: 1),
      );

      expect(limiter.resetTime, Duration.zero);
    });
  });
}
