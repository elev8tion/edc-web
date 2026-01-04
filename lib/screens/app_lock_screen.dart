import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/frosted_glass_card.dart';
import '../components/glass_button.dart';
import '../components/gradient_background.dart';
import '../features/auth/services/secure_storage_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Password-based app lock screen with glassmorphic design
///
/// Features:
/// - Beautiful glassmorphic design matching app theme
/// - Password authentication (works on all platforms including PWA)
/// - Loading states and animations
/// - Error handling with user-friendly messages
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final SecureStorageService _secureStorage = const SecureStorageService();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isAuthenticating = false;
  bool _authenticationFailed = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Auto-focus password field when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithPassword() async {
    if (_isAuthenticating) return;

    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _authenticationFailed = true;
        _errorMessage = 'Please enter your password';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authenticationFailed = false;
      _errorMessage = null;
    });

    try {
      // Trigger haptic feedback
      HapticFeedback.mediumImpact();

      final authenticated = await _secureStorage.verifyAppLockPassword(password);

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
            _errorMessage = 'Incorrect password. Please try again.';
            _passwordController.clear();
          });
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authenticationFailed = true;
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _passwordController.clear();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.localeName == 'es';

    return Scaffold(
      body: Stack(
        children: [
          // Use actual app gradient background
          const GradientBackground(),
          SafeArea(
            child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
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
                    'Enter your password to continue',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Glass card with password input
                  FrostedGlassCard(
                    intensity: GlassIntensity.medium,
                    padding: const EdgeInsets.all(32),
                    borderRadius: 24,
                    child: Column(
                      children: [
                        // Lock icon
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
                            _authenticationFailed ? Icons.lock_outline : Icons.lock,
                            size: 40,
                            color: _authenticationFailed
                                ? Colors.red.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Password input field
                        TextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          enabled: !_isAuthenticating,
                          onSubmitted: (_) => _authenticateWithPassword(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            prefixIcon: Icon(
                              Icons.password,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            errorText: _errorMessage,
                            errorStyle: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.goldColor,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.withValues(alpha: 0.8),
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

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
                                'Verifying...',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else if (_authenticationFailed && _errorMessage != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 20,
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.red.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Unlock button
                        GlassButton(
                          text: _isAuthenticating
                              ? 'Verifying...'
                              : _authenticationFailed
                                  ? 'Try Again'
                                  : 'Unlock',
                          onPressed: _isAuthenticating ? null : _authenticateWithPassword,
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}
