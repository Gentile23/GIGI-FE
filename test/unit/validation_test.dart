// Test for email validation utilities
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email Validation', () {
    bool isValidEmail(String email) {
      final emailRegex = RegExp(r'^[\w\+\-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email);
    }

    test('Valid email addresses should pass', () {
      expect(isValidEmail('test@example.com'), true);
      expect(isValidEmail('user.name@domain.org'), true);
      expect(isValidEmail('user+tag@company.co.uk'), true);
      expect(isValidEmail('email123@test.it'), true);
    });

    test('Invalid email addresses should fail', () {
      expect(isValidEmail(''), false);
      expect(isValidEmail('notanemail'), false);
      expect(isValidEmail('@nodomain.com'), false);
      expect(isValidEmail('no@'), false);
      expect(isValidEmail('spaces in@email.com'), false);
      expect(isValidEmail('missing.domain@'), false);
    });
  });

  group('Password Validation', () {
    bool isValidPassword(String password) {
      return password.length >= 6;
    }

    test('Valid passwords should pass (6+ characters)', () {
      expect(isValidPassword('123456'), true);
      expect(isValidPassword('password'), true);
      expect(isValidPassword('MySecurePassword123!'), true);
    });

    test('Short passwords should fail', () {
      expect(isValidPassword(''), false);
      expect(isValidPassword('12345'), false);
      expect(isValidPassword('abc'), false);
    });
  });

  group('Password Confirmation', () {
    bool passwordsMatch(String password, String confirmPassword) {
      return password == confirmPassword && password.isNotEmpty;
    }

    test('Matching passwords should pass', () {
      expect(passwordsMatch('password123', 'password123'), true);
      expect(passwordsMatch('SecurePass!', 'SecurePass!'), true);
    });

    test('Non-matching passwords should fail', () {
      expect(passwordsMatch('password123', 'password124'), false);
      expect(passwordsMatch('Password', 'password'), false);
      expect(passwordsMatch('', ''), false);
    });
  });

  group('Name Validation', () {
    bool isValidName(String name) {
      return name.trim().isNotEmpty && name.length >= 2;
    }

    test('Valid names should pass', () {
      expect(isValidName('John'), true);
      expect(isValidName('Maria Rossi'), true);
      expect(isValidName('José García'), true);
    });

    test('Invalid names should fail', () {
      expect(isValidName(''), false);
      expect(isValidName(' '), false);
      expect(isValidName('A'), false);
    });
  });
}
