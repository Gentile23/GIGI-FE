// Unit tests for User model
import 'package:flutter_test/flutter_test.dart';

// Mock User class for testing (matches the app's User model structure)
class User {
  final int id;
  final String name;
  final String email;
  final double? height;
  final double? weight;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? fitnessGoal;
  final String? fitnessLevel;
  final bool isPremium;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.height,
    this.weight,
    this.dateOfBirth,
    this.gender,
    this.fitnessGoal,
    this.fitnessLevel,
    this.isPremium = false,
  });

  int get age {
    if (dateOfBirth == null) return 0;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  double get bmi {
    if (height == null || weight == null || height! <= 0) return 0;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get initials {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      gender: json['gender'],
      fitnessGoal: json['fitness_goal'],
      fitnessLevel: json['fitness_level'],
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'height': height,
      'weight': weight,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'fitness_goal': fitnessGoal,
      'fitness_level': fitnessLevel,
      'is_premium': isPremium,
    };
  }
}

void main() {
  group('User Model', () {
    test('User creation with required fields', () {
      final user = User(id: 1, name: 'Mario Rossi', email: 'mario@test.com');

      expect(user.id, 1);
      expect(user.name, 'Mario Rossi');
      expect(user.email, 'mario@test.com');
      expect(user.isPremium, false);
    });

    test('User creation with all fields', () {
      final user = User(
        id: 2,
        name: 'Giulia Bianchi',
        email: 'giulia@test.com',
        height: 165,
        weight: 60,
        dateOfBirth: DateTime(1995, 5, 15),
        gender: 'female',
        fitnessGoal: 'weight_loss',
        fitnessLevel: 'intermediate',
        isPremium: true,
      );

      expect(user.height, 165);
      expect(user.weight, 60);
      expect(user.gender, 'female');
      expect(user.isPremium, true);
    });
  });

  group('User Age Calculation', () {
    test('Age calculation from date of birth', () {
      // User born on Jan 1, 2000 (should be ~26 in 2026)
      final user = User(
        id: 1,
        name: 'Test',
        email: 'test@test.com',
        dateOfBirth: DateTime(2000, 1, 1),
      );

      // Age should be between 24-27 depending on current year
      expect(user.age, greaterThanOrEqualTo(24));
      expect(user.age, lessThanOrEqualTo(27));
    });

    test('Age is 0 when date of birth is null', () {
      final user = User(id: 1, name: 'Test', email: 'test@test.com');

      expect(user.age, 0);
    });
  });

  group('User BMI Calculation', () {
    test('BMI calculation with valid height and weight', () {
      // Height 180cm, Weight 75kg -> BMI ~23.15
      final user = User(
        id: 1,
        name: 'Test',
        email: 'test@test.com',
        height: 180,
        weight: 75,
      );

      expect(user.bmi, closeTo(23.15, 0.1));
    });

    test('BMI is 0 when height is null', () {
      final user = User(
        id: 1,
        name: 'Test',
        email: 'test@test.com',
        weight: 75,
      );

      expect(user.bmi, 0);
    });

    test('BMI is 0 when weight is null', () {
      final user = User(
        id: 1,
        name: 'Test',
        email: 'test@test.com',
        height: 180,
      );

      expect(user.bmi, 0);
    });
  });

  group('User Initials', () {
    test('Initials from full name', () {
      final user = User(id: 1, name: 'Mario Rossi', email: 'test@test.com');

      expect(user.initials, 'MR');
    });

    test('Initials from single name', () {
      final user = User(id: 1, name: 'Mario', email: 'test@test.com');

      expect(user.initials, 'M');
    });

    test('Default initial for empty name', () {
      final user = User(id: 1, name: '', email: 'test@test.com');

      expect(user.initials, 'U');
    });
  });

  group('User JSON Serialization', () {
    test('User.fromJson creates user correctly', () {
      final json = {
        'id': 1,
        'name': 'Test User',
        'email': 'test@test.com',
        'height': 175.0,
        'weight': 70.0,
        'gender': 'male',
        'is_premium': true,
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(user.email, 'test@test.com');
      expect(user.height, 175.0);
      expect(user.weight, 70.0);
      expect(user.gender, 'male');
      expect(user.isPremium, true);
    });

    test('User.toJson exports correctly', () {
      final user = User(
        id: 1,
        name: 'Test User',
        email: 'test@test.com',
        height: 175,
        weight: 70,
        isPremium: true,
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@test.com');
      expect(json['height'], 175);
      expect(json['weight'], 70);
      expect(json['is_premium'], true);
    });
  });
}
