import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../core/services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

/// Dialog to prompt user to enable biometric app lock during onboarding
class BiometricSetupDialog {
  static Future<void> show(BuildContext context) async {
    final LocalAuthentication localAuth = LocalAuthentication();

    // Check if device supports biometrics
    bool canCheckBiometrics = false;
    bool isDeviceSupported = false;
    List<BiometricType> availableBiometrics = [];

    try {
      canCheckBiometrics = await localAuth.canCheckBiometrics;
      isDeviceSupported = await localAuth.isDeviceSupported();
      availableBiometrics = await localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
    }

    // If device doesn't support biometrics, skip this dialog
    if (!canCheckBiometrics || !isDeviceSupported || availableBiometrics.isEmpty) {
      final prefsService = await PreferencesService.getInstance();
      await prefsService.setBiometricSetupCompleted();
      return;
    }

    // Determine biometric type name for display
    String biometricName = 'Biometric';
    if (availableBiometrics.contains(BiometricType.face)) {
      biometricName = 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      biometricName = 'Touch ID / Fingerprint';
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // slate-800
                Color(0xFF0F172A), // slate-900
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    availableBiometrics.contains(BiometricType.face)
                        ? Icons.face
                        : Icons.fingerprint,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Protect Your App',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Keep your prayers, devotionals, and spiritual conversations private with $biometricName.',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Enable button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Attempt to authenticate to verify it works
                        final authenticated = await localAuth.authenticate(
                          localizedReason: AppLocalizations.of(context).enableAppLockPrompt,
                          options: const AuthenticationOptions(
                            useErrorDialogs: true,
                            stickyAuth: true,
                            biometricOnly: false, // Allow PIN fallback
                          ),
                        );

                        if (authenticated) {
                          // Enable app lock
                          final prefsService = await PreferencesService.getInstance();
                          await prefsService.setAppLockEnabled(true);
                          await prefsService.setBiometricSetupCompleted();

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          // Show success message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                content: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade300, size: 20),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'App lock enabled. Your content is now protected.',
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        } else {
                          // Authentication failed - just close dialog
                          final prefsService = await PreferencesService.getInstance();
                          await prefsService.setBiometricSetupCompleted();

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      } catch (e) {
                        debugPrint('Biometric setup error: $e');

                        // Mark as completed even if error
                        final prefsService = await PreferencesService.getInstance();
                        await prefsService.setBiometricSetupCompleted();

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          availableBiometrics.contains(BiometricType.face)
                              ? Icons.face
                              : Icons.fingerprint,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enable $biometricName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Skip button
                TextButton(
                  onPressed: () async {
                    final prefsService = await PreferencesService.getInstance();
                    await prefsService.setBiometricSetupCompleted();

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Privacy note
                Text(
                  'You can change this anytime in Settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
