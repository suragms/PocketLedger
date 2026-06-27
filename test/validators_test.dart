import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator should reject invalid emails', () {
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail('invalid-email'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@doe'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@doe.'), 'Enter a valid email address');
    });

    test('Email validator should accept valid emails', () {
      expect(Validators.validateEmail('john.doe@example.com'), null);
      expect(Validators.validateEmail('user@domain.co.in'), null);
    });

    test('Password validator should enforce constraints', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword('short'), 'Password must be at least 8 characters long');
      expect(Validators.validatePassword('onlyletters'), 'Password must contain at least 1 letter and 1 number');
      expect(Validators.validatePassword('12345678'), 'Password must contain at least 1 letter and 1 number');
    });

    test('Password validator should accept valid passwords', () {
      expect(Validators.validatePassword('pass1234'), null);
      expect(Validators.validatePassword('SecurePassword88!'), null);
    });

    test('Confirm Password validator should check equality', () {
      expect(Validators.validateConfirmPassword('', 'password123'), 'Confirm password is required');
      expect(Validators.validateConfirmPassword('mismatch123', 'password123'), 'Passwords do not match');
      expect(Validators.validateConfirmPassword('password123', 'password123'), null);
    });

    test('Amount validator should check bounds', () {
      expect(Validators.validateAmount(''), 'Amount is required');
      expect(Validators.validateAmount('not-a-number'), 'Enter a valid number');
      expect(Validators.validateAmount('-10'), 'Amount must be greater than zero');
      expect(Validators.validateAmount('0'), 'Amount must be greater than zero');
      expect(Validators.validateAmount('150.50'), null);
      expect(Validators.validateAmount('1000000000'), 'Amount exceeds maximum limit');
    });

    test('Password strength evaluator should work correctly', () {
      expect(Validators.evaluatePasswordStrength(''), '');
      expect(Validators.evaluatePasswordStrength('123'), 'Weak');
      expect(Validators.evaluatePasswordStrength('letters'), 'Weak');
      expect(Validators.evaluatePasswordStrength('letters12'), 'Medium');
      expect(Validators.evaluatePasswordStrength('L3tt3r5!!'), 'Strong');
    });
  });
}
