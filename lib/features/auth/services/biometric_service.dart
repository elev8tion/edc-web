import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Biometric authentication service
///
/// This service provides biometric authentication capabilities including
/// fingerprint, face ID, and other device-supported biometric methods.
class BiometricService {
  static const MethodChannel _channel = MethodChannel('biometric_auth'); // ignore: unused_field

  /// Check if biometric authentication is available on the device
  Future<bool> canCheckBiometrics() async {
    try {
      if (kIsWeb) {
        // Web doesn't support biometric authentication
        return false;
      }

      // For now, we'll simulate biometric capability based on platform
      // In a real implementation, you would use local_auth package
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (!await canCheckBiometrics()) {
        return [];
      }

      // Simulate different biometric types based on platform
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return [BiometricType.face, BiometricType.fingerprint];
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return [BiometricType.fingerprint];
      }

      return [];
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometric authentication
  Future<bool> authenticate({
    String localizedFallbackTitle = 'Use PIN',
    String androidSignInTitle = 'Biometric Authentication',
    String androidCancelButton = 'Cancel',
    String androidGoToSettingsDescription = 'Please set up biometric authentication',
    bool biometricOnly = false,
    bool stickyAuth = false,
  }) async {
    try {
      if (!await canCheckBiometrics()) {
        throw const BiometricException('Biometric authentication not available');
      }

      // For development/testing, we'll simulate successful authentication
      // In production, replace this with actual biometric authentication
      if (kDebugMode) {
        // Simulate authentication delay
        await Future.delayed(const Duration(milliseconds: 1500));

        // Simulate 90% success rate for testing
        return DateTime.now().millisecond % 10 != 0;
      }

      // In production, this would use the local_auth package:
      // final LocalAuthentication auth = LocalAuthentication();
      // return await auth.authenticate(
      //   localizedFallbackTitle: localizedFallbackTitle,
      //   authMessages: [
      //     AndroidAuthMessages(
      //       signInTitle: androidSignInTitle,
      //       cancelButton: androidCancelButton,
      //       goToSettingsDescription: androidGoToSettingsDescription,
      //     ),
      //   ],
      //   options: AuthenticationOptions(
      //     biometricOnly: biometricOnly,
      //     stickyAuth: stickyAuth,
      //   ),
      // );

      return false;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      throw BiometricException('Authentication failed: $e');
    }
  }

  /// Check if device supports strong biometric authentication
  Future<bool> isStrongBiometricSupported() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();

      // Face ID and newer fingerprint sensors are considered strong
      return availableBiometrics.contains(BiometricType.face) ||
             availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      debugPrint('Error checking strong biometric support: $e');
      return false;
    }
  }

  /// Stop biometric authentication
  Future<void> stopAuthentication() async {
    try {
      // Implementation would stop ongoing authentication
      // For now, this is a no-op since we're simulating
    } catch (e) {
      debugPrint('Error stopping authentication: $e');
    }
  }

  /// Get biometric authentication settings
  Future<BiometricSettings> getSettings() async {
    try {
      final canCheck = await canCheckBiometrics();
      final availableTypes = await getAvailableBiometrics();
      final isStrong = await isStrongBiometricSupported();

      return BiometricSettings(
        isAvailable: canCheck,
        availableTypes: availableTypes,
        isStrongSupported: isStrong,
        platformSupport: _getPlatformSupport(),
      );
    } catch (e) {
      debugPrint('Error getting biometric settings: $e');
      return const BiometricSettings(
        isAvailable: false,
        availableTypes: [],
        isStrongSupported: false,
        platformSupport: BiometricPlatformSupport.none,
      );
    }
  }

  /// Get platform support level
  BiometricPlatformSupport _getPlatformSupport() {
    if (kIsWeb) {
      return BiometricPlatformSupport.none;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return BiometricPlatformSupport.full;
      case TargetPlatform.android:
        return BiometricPlatformSupport.full;
      case TargetPlatform.windows:
        return BiometricPlatformSupport.limited;
      case TargetPlatform.macOS:
        return BiometricPlatformSupport.full;
      case TargetPlatform.linux:
        return BiometricPlatformSupport.none;
      default:
        return BiometricPlatformSupport.none;
    }
  }

  /// Get user-friendly description of available biometrics
  Future<String> getBiometricDescription() async {
    try {
      final availableTypes = await getAvailableBiometrics();

      if (availableTypes.isEmpty) {
        return 'No biometric authentication available';
      }

      final descriptions = availableTypes.map((type) {
        switch (type) {
          case BiometricType.face:
            return 'Face ID';
          case BiometricType.fingerprint:
            return 'Fingerprint';
          case BiometricType.iris:
            return 'Iris scan';
          case BiometricType.voice:
            return 'Voice recognition';
        }
      }).toList();

      if (descriptions.length == 1) {
        return descriptions.first;
      } else if (descriptions.length == 2) {
        return '${descriptions.first} or ${descriptions.last}';
      } else {
        final last = descriptions.removeLast();
        return '${descriptions.join(', ')}, or $last';
      }
    } catch (e) {
      return 'Biometric authentication';
    }
  }
}

/// Types of biometric authentication
enum BiometricType {
  face,
  fingerprint,
  iris,
  voice,
}

/// Platform support levels for biometric authentication
enum BiometricPlatformSupport {
  none,
  limited,
  full,
}

/// Biometric authentication settings
class BiometricSettings {
  final bool isAvailable;
  final List<BiometricType> availableTypes;
  final bool isStrongSupported;
  final BiometricPlatformSupport platformSupport;

  const BiometricSettings({
    required this.isAvailable,
    required this.availableTypes,
    required this.isStrongSupported,
    required this.platformSupport,
  });

  /// Check if a specific biometric type is available
  bool hasType(BiometricType type) {
    return availableTypes.contains(type);
  }

  /// Get a user-friendly description of capabilities
  String get description {
    if (!isAvailable) {
      return 'Biometric authentication not available on this device';
    }

    final typeNames = availableTypes.map((type) {
      switch (type) {
        case BiometricType.face:
          return 'Face ID';
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.voice:
          return 'Voice';
      }
    }).toList();

    if (typeNames.isEmpty) {
      return 'Biometric authentication available';
    } else if (typeNames.length == 1) {
      return '${typeNames.first} available';
    } else {
      return '${typeNames.join(', ')} available';
    }
  }

  /// Convert to JSON for storage/debugging
  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'availableTypes': availableTypes.map((e) => e.name).toList(),
      'isStrongSupported': isStrongSupported,
      'platformSupport': platformSupport.name,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'BiometricSettings(available: $isAvailable, types: $availableTypes, strong: $isStrongSupported, platform: $platformSupport)';
  }
}

/// Custom exception for biometric authentication errors
class BiometricException implements Exception {
  final String message;
  final String? code;

  const BiometricException(this.message, [this.code]);

  @override
  String toString() {
    if (code != null) {
      return 'BiometricException($code): $message';
    }
    return 'BiometricException: $message';
  }
}

/// Biometric authentication result
class BiometricResult {
  final bool success;
  final String? error;
  final BiometricType? usedType;

  const BiometricResult({
    required this.success,
    this.error,
    this.usedType,
  });

  factory BiometricResult.success([BiometricType? type]) {
    return BiometricResult(success: true, usedType: type);
  }

  factory BiometricResult.failure(String error) {
    return BiometricResult(success: false, error: error);
  }

  @override
  String toString() {
    if (success) {
      return 'BiometricResult: Success${usedType != null ? ' (${usedType!.name})' : ''}';
    } else {
      return 'BiometricResult: Failed - ${error ?? 'Unknown error'}';
    }
  }
}
