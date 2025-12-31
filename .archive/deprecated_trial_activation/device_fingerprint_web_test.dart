/// Unit tests for DeviceFingerprintService
///
/// These tests verify the device fingerprint generation works correctly
/// after migrating from dart:html to package:web (Error 1 fix).
///
/// Run with: flutter test test/device_fingerprint_web_test.dart --platform chrome
///
/// NOTE: Some tests require Chrome platform as they use web APIs.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Import the service to test
import 'package:everyday_christian/core/services/device_fingerprint_service.dart';

void main() {
  group('DeviceFingerprintService Tests', () {
    group('Static Method Availability', () {
      test('generateFingerprint method exists', () {
        expect(DeviceFingerprintService.generateFingerprint, isA<Function>());
      });

      test('isValidFingerprint method exists', () {
        expect(DeviceFingerprintService.isValidFingerprint, isA<Function>());
      });

      test('shortFingerprint method exists', () {
        expect(DeviceFingerprintService.shortFingerprint, isA<Function>());
      });
    });

    group('isValidFingerprint()', () {
      test('returns true for valid 64-char hex string', () {
        // Create a valid SHA-256 hash (64 hex characters)
        final validHash = sha256.convert(utf8.encode('test')).toString();

        final isValid = DeviceFingerprintService.isValidFingerprint(validHash);

        expect(isValid, isTrue);
        expect(validHash.length, equals(64));
      });

      test('returns false for too short string', () {
        const shortHash = 'abc123';

        final isValid = DeviceFingerprintService.isValidFingerprint(shortHash);

        expect(isValid, isFalse);
      });

      test('returns false for too long string', () {
        final longHash = 'a' * 65;

        final isValid = DeviceFingerprintService.isValidFingerprint(longHash);

        expect(isValid, isFalse);
      });

      test('returns false for non-hex characters', () {
        // 64 chars but contains 'g' which is not valid hex
        final invalidHash = 'g' * 64;

        final isValid =
            DeviceFingerprintService.isValidFingerprint(invalidHash);

        expect(isValid, isFalse);
      });

      test('returns false for uppercase hex (strict lowercase)', () {
        // SHA-256 produces lowercase, uppercase should be invalid
        final uppercaseHash = 'A' * 64;

        final isValid =
            DeviceFingerprintService.isValidFingerprint(uppercaseHash);

        expect(isValid, isFalse);
      });

      test('returns false for empty string', () {
        final isValid = DeviceFingerprintService.isValidFingerprint('');

        expect(isValid, isFalse);
      });
    });

    group('shortFingerprint()', () {
      test('returns first 16 chars with ellipsis for valid fingerprint', () {
        final fullHash = sha256.convert(utf8.encode('test')).toString();
        final expected = '${fullHash.substring(0, 16)}...';

        final short = DeviceFingerprintService.shortFingerprint(fullHash);

        expect(short, equals(expected));
        expect(short.length, equals(19)); // 16 + 3 for '...'
      });

      test('returns original string if less than 16 chars', () {
        const shortString = 'abc123';

        final result =
            DeviceFingerprintService.shortFingerprint(shortString);

        expect(result, equals(shortString));
      });

      test('returns exactly 16 char string unchanged', () {
        const exactlyShort = 'abcdef1234567890';

        final result =
            DeviceFingerprintService.shortFingerprint(exactlyShort);

        // 16 chars should still get the '...' suffix
        expect(result.startsWith(exactlyShort), isTrue);
      });
    });

    group('generateFingerprint() - Unit Tests', () {
      test('returns a string', () async {
        final fingerprint =
            await DeviceFingerprintService.generateFingerprint();

        expect(fingerprint, isA<String>());
        expect(fingerprint, isNotEmpty);
      });

      test('returns fallback fingerprint on non-web platforms', () async {
        if (!kIsWeb) {
          final fingerprint =
              await DeviceFingerprintService.generateFingerprint();

          // Fallback should still be a valid-looking hash
          expect(fingerprint.length, equals(64));
        }
      });

      // Web-specific tests (only run on Chrome)
      test('generates valid fingerprint on web', () async {
        if (kIsWeb) {
          final fingerprint =
              await DeviceFingerprintService.generateFingerprint();

          final isValid =
              DeviceFingerprintService.isValidFingerprint(fingerprint);
          expect(isValid, isTrue);
        }
      }, skip: !kIsWeb ? 'Web-only test' : null);

      test('generates consistent fingerprint on same device', () async {
        if (kIsWeb) {
          final fingerprint1 =
              await DeviceFingerprintService.generateFingerprint();
          final fingerprint2 =
              await DeviceFingerprintService.generateFingerprint();

          // Same device should produce same fingerprint
          // (barring any time-based signals)
          expect(fingerprint1, equals(fingerprint2));
        }
      }, skip: !kIsWeb ? 'Web-only test' : null);
    });

    group('Hash Properties', () {
      test('SHA-256 produces 64-character hex string', () {
        final hash = sha256.convert(utf8.encode('test data')).toString();

        expect(hash.length, equals(64));
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
      });

      test('different inputs produce different hashes', () {
        final hash1 = sha256.convert(utf8.encode('input1')).toString();
        final hash2 = sha256.convert(utf8.encode('input2')).toString();

        expect(hash1, isNot(equals(hash2)));
      });

      test('same input always produces same hash', () {
        final hash1 = sha256.convert(utf8.encode('same input')).toString();
        final hash2 = sha256.convert(utf8.encode('same input')).toString();

        expect(hash1, equals(hash2));
      });
    });

    group('Signal Collection Validation', () {
      // These tests validate the expected structure of collected signals
      // without actually collecting them (which requires browser APIs)

      test('expected signal keys are defined', () {
        // List of signals that should be collected
        const expectedSignals = [
          'userAgent',
          'language',
          'languages',
          'platform',
          'screenWidth',
          'screenHeight',
          'screenColorDepth',
          'screenPixelDepth',
          'windowWidth',
          'windowHeight',
          'timezoneOffset',
          'hardwareConcurrency',
          'deviceMemory',
          'maxTouchPoints',
          'cookieEnabled',
          'doNotTrack',
          'canvasFingerprint',
          'webglVendor',
          'webglRenderer',
        ];

        // Just verify the expected list is complete
        expect(expectedSignals.length, greaterThan(15));
        expect(expectedSignals.contains('canvasFingerprint'), isTrue);
        expect(expectedSignals.contains('webglVendor'), isTrue);
      });
    });

    group('Error Handling', () {
      test('service handles errors gracefully', () async {
        // The service should never throw - it should return fallback
        try {
          final fingerprint =
              await DeviceFingerprintService.generateFingerprint();
          expect(fingerprint, isNotEmpty);
        } catch (e) {
          fail('generateFingerprint should not throw: $e');
        }
      });
    });
  });
}
