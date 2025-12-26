import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../components/pin_setup_dialog.dart';
import '../features/auth/services/biometric_service.dart';
import '../features/auth/services/secure_storage_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Custom app lock screen with glassmorphic design and biometric authentication
///
/// Features:
/// - Beautiful glassmorphic design matching app theme
/// - Biometric authentication (Face ID/Touch ID)
/// - Fallback to passcode if biometrics fail
/// - Loading states and animations
/// - Error handling with user-friendly messages
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final BiometricService _biometricService = BiometricService();
  final SecureStorageService _secureStorage = const SecureStorageService();

  bool _isAuthenticating = false;
  bool _authenticationFailed = false;
  String? _errorMessage;
  bool _biometricsAvailable = false;
  bool _appPinAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAvailability();
    _checkAppPinAvailability();

    // Auto-trigger biometric authentication on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      final available = await _biometricService.canCheckBiometrics();
      if (mounted) {
        setState(() {
          _biometricsAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
    }
  }

  Future<void> _checkAppPinAvailability() async {
    try {
      final hasPin = await _secureStorage.hasAppPin();
      if (mounted) {
        setState(() {
          _appPinAvailable = hasPin;
        });
      }
    } catch (e) {
      debugPrint('Error checking app PIN availability: $e');
    }
  }

  Future<void> _showPasscodeDialog() async {
    // Check if app PIN is set
    final hasPin = await _secureStorage.hasAppPin();

    if (!hasPin) {
      // No PIN set - offer to create one
      final shouldCreate = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Text(
            'No PIN Set',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You haven\'t set up an app PIN yet. Would you like to create one now?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create PIN'),
            ),
          ],
        ),
      );

      if (shouldCreate == true && mounted) {
        // Show PIN setup dialog
        final created = await PinSetupDialog.show(context);
        if (created && mounted) {
          // PIN created successfully - update availability
          setState(() {
            _appPinAvailable = true;
          });

          // Navigate to home
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
      return;
    }

    // PIN is set - show verification dialog
    final passcodeController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Text(
            'Enter PIN',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your app PIN to unlock',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passcodeController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 8,
                  ),
                  errorText: errorText,
                  errorStyle: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 12,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.goldColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (pin) async {
                  if (pin.length < 4) {
                    setDialogState(() {
                      errorText = 'PIN must be at least 4 digits';
                    });
                    HapticFeedback.heavyImpact();
                    return;
                  }

                  final isValid = await _secureStorage.verifyAppPin(pin);
                  if (isValid) {
                    Navigator.of(context).pop(true);
                  } else {
                    setDialogState(() {
                      errorText = 'Incorrect PIN. Please try again.';
                    });
                    passcodeController.clear();
                    HapticFeedback.heavyImpact();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = passcodeController.text;

                if (pin.length < 4) {
                  setDialogState(() {
                    errorText = 'PIN must be at least 4 digits';
                  });
                  HapticFeedback.heavyImpact();
                  return;
                }

                final isValid = await _secureStorage.verifyAppPin(pin);
                if (isValid) {
                  Navigator.of(context).pop(true);
                } else {
                  setDialogState(() {
                    errorText = 'Incorrect PIN. Please try again.';
                  });
                  passcodeController.clear();
                  HapticFeedback.heavyImpact();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );

    passcodeController.dispose();

    if (result == true && mounted) {
      // PIN verified - navigate to home
      HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _authenticationFailed = false;
      _errorMessage = null;
    });

    try {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      final authenticated = await _biometricService.authenticate(
        reason: 'Unlock Everyday Christian',
        biometricOnly: false,
      );

      if (mounted) {
        if (authenticated) {
          // Success! Navigate to home
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          // Authentication failed
          setState(() {
            _authenticationFailed = true;
            _errorMessage = 'Authentication failed. Please try again.';
          });
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authenticationFailed = true;
          _errorMessage = 'An unexpected error occurred. Please try again.';
        });
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  String _getBiometricTypeText() {
    if (!_biometricsAvailable) return 'Biometric Authentication';

    // Platform-specific naming
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'Face ID or Touch ID';
    } else {
      return 'Fingerprint';
    }
  }

  IconData _getBiometricIcon() {
    if (!_biometricsAvailable) return Icons.lock;

    // Platform-specific icons
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Icons.face;
    } else {
      return Icons.fingerprint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.localeName == 'es';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFFf093fb),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo (no animation)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            isSpanish
                                ? 'assets/images/logo_spanish.png'
                                : 'assets/images/logo_cropped.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Welcome text
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Unlock to continue your journey',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 60),

                      // Glass card with biometric info
                      FrostedGlassCard(
                        intensity: GlassIntensity.medium,
                        padding: const EdgeInsets.all(32),
                        borderRadius: 24,
                        child: Column(
                          children: [
                            // Biometric icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.2),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _getBiometricIcon(),
                                size: 40,
                                color: _authenticationFailed
                                    ? Colors.red.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Status text
                            if (_isAuthenticating)
                              Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Authenticating...',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else if (_authenticationFailed && _errorMessage != null)
                              Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 32,
                                    color: Colors.red.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.red.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Tap to unlock with ${_getBiometricTypeText()}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),

                            const SizedBox(height: 32),

                            // Unlock button
                            GlassButton(
                              text: _isAuthenticating
                                  ? 'Authenticating...'
                                  : _authenticationFailed
                                      ? 'Try Again'
                                      : 'Unlock',
                              onPressed: _isAuthenticating
                                  ? null
                                  : _authenticateWithBiometrics,
                              isLoading: _isAuthenticating,
                              height: 56,
                              width: double.infinity,
                              enablePressAnimation: true,
                              enableHaptics: true,
                              blurStrength: 40,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fallback text
                      if (!_isAuthenticating && _biometricsAvailable)
                        TextButton(
                          onPressed: _showPasscodeDialog,
                          child: Text(
                            'Use Passcode Instead',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
