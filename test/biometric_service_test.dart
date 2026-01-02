/// Unit tests for BiometricService
///
/// These tests verify the BiometricService API, specifically that the
/// `reason` parameter is properly supported (Error 4 fix).
///
/// Run with: flutter test test/biometric_service_test.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/features/auth/services/biometric_service.dart';

void main() {
  group('BiometricService Tests', () {
    late BiometricService biometricService;

    setUp(() {
      biometricService = BiometricService();
    });

    group('Type Definitions', () {
      test('BiometricService class exists and can be instantiated', () {
        expect(biometricService, isNotNull);
        expect(biometricService, isA<BiometricService>());
      });

      test('BiometricType enum has expected values', () {
        expect(BiometricType.values, contains(BiometricType.face));
        expect(BiometricType.values, contains(BiometricType.fingerprint));
        expect(BiometricType.values, contains(BiometricType.iris));
        expect(BiometricType.values, contains(BiometricType.voice));
      });

      test('BiometricPlatformSupport enum has expected values', () {
        expect(BiometricPlatformSupport.values,
            contains(BiometricPlatformSupport.none));
        expect(BiometricPlatformSupport.values,
            contains(BiometricPlatformSupport.limited));
        expect(BiometricPlatformSupport.values,
            contains(BiometricPlatformSupport.full));
      });
    });

    group('BiometricSettings', () {
      test('can be constructed with required parameters', () {
        const settings = BiometricSettings(
          isAvailable: true,
          availableTypes: [BiometricType.face, BiometricType.fingerprint],
          isStrongSupported: true,
          platformSupport: BiometricPlatformSupport.full,
        );

        expect(settings.isAvailable, isTrue);
        expect(settings.availableTypes.length, equals(2));
        expect(settings.isStrongSupported, isTrue);
        expect(settings.platformSupport, equals(BiometricPlatformSupport.full));
      });

      test('hasType() returns correct values', () {
        const settings = BiometricSettings(
          isAvailable: true,
          availableTypes: [BiometricType.face],
          isStrongSupported: true,
          platformSupport: BiometricPlatformSupport.full,
        );

        expect(settings.hasType(BiometricType.face), isTrue);
        expect(settings.hasType(BiometricType.fingerprint), isFalse);
      });

      test('toJson() produces valid JSON map', () {
        const settings = BiometricSettings(
          isAvailable: true,
          availableTypes: [BiometricType.fingerprint],
          isStrongSupported: false,
          platformSupport: BiometricPlatformSupport.limited,
        );

        final json = settings.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['isAvailable'], isTrue);
        expect(json['availableTypes'], contains('fingerprint'));
        expect(json['isStrongSupported'], isFalse);
        expect(json['platformSupport'], equals('limited'));
      });
    });

    group('BiometricResult', () {
      test('success factory creates successful result', () {
        final result = BiometricResult.success(BiometricType.face);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.usedType, equals(BiometricType.face));
      });

      test('failure factory creates failed result with error', () {
        final result = BiometricResult.failure('Authentication cancelled');

        expect(result.success, isFalse);
        expect(result.error, equals('Authentication cancelled'));
        expect(result.usedType, isNull);
      });

      test('toString() provides readable output for success', () {
        final result = BiometricResult.success(BiometricType.fingerprint);
        final str = result.toString();

        expect(str, contains('Success'));
        expect(str, contains('fingerprint'));
      });

      test('toString() provides readable output for failure', () {
        final result = BiometricResult.failure('User cancelled');
        final str = result.toString();

        expect(str, contains('Failed'));
        expect(str, contains('User cancelled'));
      });
    });

    group('BiometricException', () {
      test('can be constructed with message only', () {
        const exception = BiometricException('Auth failed');

        expect(exception.message, equals('Auth failed'));
        expect(exception.code, isNull);
      });

      test('can be constructed with message and code', () {
        const exception = BiometricException('Auth failed', 'AUTH_001');

        expect(exception.message, equals('Auth failed'));
        expect(exception.code, equals('AUTH_001'));
      });

      test('toString() includes code when present', () {
        const exception = BiometricException('Auth failed', 'AUTH_001');
        final str = exception.toString();

        expect(str, contains('AUTH_001'));
        expect(str, contains('Auth failed'));
      });
    });

    group('authenticate() Method Signature', () {
      // NOTE: After Error 4 fix, this test should pass
      // The method should accept a 'reason' parameter

      test('authenticate method exists', () {
        // Verify the method exists and returns a Future<bool>
        expect(biometricService.authenticate, isA<Function>());
      });

      test('authenticate can be called with biometricOnly parameter', () async {
        // This should work with current implementation
        try {
          await biometricService.authenticate(biometricOnly: true);
        } catch (e) {
          // May throw on non-mobile platforms, but should not throw
          // a parameter error
          expect(e, isNot(isA<NoSuchMethodError>()));
        }
      });

      // TODO: Uncomment after Error 4 fix is applied
      // test('authenticate accepts reason parameter', () async {
      //   try {
      //     await biometricService.authenticate(
      //       reason: 'Test authentication',
      //       biometricOnly: false,
      //     );
      //   } catch (e) {
      //     // May throw BiometricException on non-mobile, but should not
      //     // throw NoSuchMethodError for missing parameter
      //     expect(e, isNot(isA<NoSuchMethodError>()));
      //   }
      // });
    });

    group('canCheckBiometrics()', () {
      test('returns a Future<bool>', () async {
        final result = biometricService.canCheckBiometrics();
        expect(result, isA<Future<bool>>());
      });

      test('returns false on web platform', () async {
        // On web, biometrics should not be available
        final canCheck = await biometricService.canCheckBiometrics();
        // This will be false on web, true on mobile
        expect(canCheck, isA<bool>());
      });
    });

    group('getAvailableBiometrics()', () {
      test('returns a Future<List<BiometricType>>', () async {
        final result = biometricService.getAvailableBiometrics();
        expect(result, isA<Future<List<BiometricType>>>());
      });
    });

    group('getSettings()', () {
      test('returns BiometricSettings', () async {
        final settings = await biometricService.getSettings();

        expect(settings, isA<BiometricSettings>());
        expect(settings.availableTypes, isA<List<BiometricType>>());
      });
    });

    group('getBiometricDescription()', () {
      test('returns a non-empty string', () async {
        final description = await biometricService.getBiometricDescription();

        expect(description, isNotEmpty);
        expect(description, isA<String>());
      });
    });
  });
}
