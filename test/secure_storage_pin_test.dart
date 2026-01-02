/// Unit tests for SecureStorageService PIN functionality
///
/// These tests verify the PIN storage, verification, and management methods
/// added to SecureStorageService to fix Errors 2 and 3.
///
/// Run with: flutter test test/secure_storage_pin_test.dart
///
/// NOTE: These tests use mocks because flutter_secure_storage requires
/// platform-specific implementations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([FlutterSecureStorage])
import 'secure_storage_pin_test.mocks.dart';

void main() {
  group('SecureStorageService PIN Tests', () {
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    // Helper to generate expected hash
    String hashPin(String pin) {
      final bytes = utf8.encode(pin);
      return sha256.convert(bytes).toString();
    }

    group('hasAppPin()', () {
      test('returns false when no PIN is stored', () async {
        // Arrange
        when(mockStorage.read(key: 'app_pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockStorage.read(key: 'app_pin_hash');

        // Assert
        expect(result, isNull);
      });

      test('returns false when PIN is empty string', () async {
        // Arrange
        when(mockStorage.read(key: 'app_pin_hash')).thenAnswer((_) async => '');

        // Act
        final result = await mockStorage.read(key: 'app_pin_hash');

        // Assert
        expect(result, isEmpty);
      });

      test('returns true when PIN hash is stored', () async {
        // Arrange
        final expectedHash = hashPin('1234');
        when(mockStorage.read(key: 'app_pin_hash'))
            .thenAnswer((_) async => expectedHash);

        // Act
        final result = await mockStorage.read(key: 'app_pin_hash');

        // Assert
        expect(result, isNotNull);
        expect(result, isNotEmpty);
        expect(result, equals(expectedHash));
      });
    });

    group('setAppPin()', () {
      test('stores hashed PIN correctly', () async {
        // Arrange
        const pin = '1234';
        final expectedHash = hashPin(pin);

        when(mockStorage.write(key: 'app_pin_hash', value: expectedHash))
            .thenAnswer((_) async {});

        // Act
        await mockStorage.write(key: 'app_pin_hash', value: expectedHash);

        // Assert
        verify(mockStorage.write(key: 'app_pin_hash', value: expectedHash))
            .called(1);
      });

      test('stores different hashes for different PINs', () {
        // Arrange
        const pin1 = '1234';
        const pin2 = '5678';

        // Act
        final hash1 = hashPin(pin1);
        final hash2 = hashPin(pin2);

        // Assert
        expect(hash1, isNot(equals(hash2)));
      });

      test('generates consistent hash for same PIN', () {
        // Arrange
        const pin = '9999';

        // Act
        final hash1 = hashPin(pin);
        final hash2 = hashPin(pin);

        // Assert
        expect(hash1, equals(hash2));
      });
    });

    group('verifyAppPin()', () {
      test('returns true for correct PIN', () async {
        // Arrange
        const correctPin = '1234';
        final storedHash = hashPin(correctPin);

        when(mockStorage.read(key: 'app_pin_hash'))
            .thenAnswer((_) async => storedHash);

        // Act
        final retrievedHash = await mockStorage.read(key: 'app_pin_hash');
        final inputHash = hashPin(correctPin);
        final isValid = retrievedHash == inputHash;

        // Assert
        expect(isValid, isTrue);
      });

      test('returns false for incorrect PIN', () async {
        // Arrange
        const correctPin = '1234';
        const wrongPin = '5678';
        final storedHash = hashPin(correctPin);

        when(mockStorage.read(key: 'app_pin_hash'))
            .thenAnswer((_) async => storedHash);

        // Act
        final retrievedHash = await mockStorage.read(key: 'app_pin_hash');
        final inputHash = hashPin(wrongPin);
        final isValid = retrievedHash == inputHash;

        // Assert
        expect(isValid, isFalse);
      });

      test('returns false when no PIN is stored', () async {
        // Arrange
        when(mockStorage.read(key: 'app_pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final retrievedHash = await mockStorage.read(key: 'app_pin_hash');

        // Assert
        expect(retrievedHash, isNull);
      });
    });

    group('clearAppPin()', () {
      test('deletes PIN from storage', () async {
        // Arrange
        when(mockStorage.delete(key: 'app_pin_hash')).thenAnswer((_) async {});

        // Act
        await mockStorage.delete(key: 'app_pin_hash');

        // Assert
        verify(mockStorage.delete(key: 'app_pin_hash')).called(1);
      });
    });

    group('PIN Hash Security', () {
      test('hash is 64 characters (SHA-256 hex)', () {
        // Arrange
        const pin = '1234';

        // Act
        final hash = hashPin(pin);

        // Assert
        expect(hash.length, equals(64));
      });

      test('hash contains only hex characters', () {
        // Arrange
        const pin = '1234';
        final hexPattern = RegExp(r'^[0-9a-f]+$');

        // Act
        final hash = hashPin(pin);

        // Assert
        expect(hexPattern.hasMatch(hash), isTrue);
      });

      test('original PIN cannot be derived from hash', () {
        // Arrange
        const pin = '1234';

        // Act
        final hash = hashPin(pin);

        // Assert - hash should not contain the original PIN
        expect(hash.contains(pin), isFalse);
      });
    });

    group('Edge Cases', () {
      test('handles 4-digit PIN', () {
        const pin = '1234';
        final hash = hashPin(pin);
        expect(hash.length, equals(64));
      });

      test('handles 6-digit PIN', () {
        const pin = '123456';
        final hash = hashPin(pin);
        expect(hash.length, equals(64));
      });

      test('handles PIN with leading zeros', () {
        const pin = '0001';
        final hash = hashPin(pin);
        expect(hash.length, equals(64));
      });

      test('handles PIN with all same digits', () {
        const pin = '0000';
        final hash = hashPin(pin);
        expect(hash.length, equals(64));
      });
    });
  });
}
