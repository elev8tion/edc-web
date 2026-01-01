import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass.dart';
import '../components/glass_button.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../features/auth/services/auth_service.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_utils.dart';

/// Handles password reset from URL token (web only)
///
/// When user clicks the reset password link in their email, this screen:
/// 1. Extracts the token from URL query parameters
/// 2. Shows a form to enter new password
/// 3. Calls the backend API to reset the password
/// 4. Shows success/error and navigates to sign in
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _token;

  @override
  void initState() {
    super.initState();
    _extractToken();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _extractToken() {
    // Extract token from URL query parameters
    final uri = Uri.parse(html.window.location.href);
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'No reset token found. Please request a new password reset link.';
      });
    } else {
      setState(() {
        _token = token;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider.notifier);
      final success = await authService.resetPassword(
        token: _token!,
        newPassword: _passwordController.text,
      );

      if (success) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        // Wait briefly then navigate to sign in
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          NavigationService.pushReplacementNamed(AppRoutes.auth);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reset password. The link may have expired.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }
    if (value.length < 6) {
      return l10n.passwordMinLength;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return l10n.pleaseConfirmPassword;
    }
    if (value != _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Show success state
    if (_isSuccess) {
      return Scaffold(
        body: Stack(
          children: [
            const GradientBackground(),
            Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      l10n.passwordResetSuccess,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      l10n.redirectingToSignIn,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show error state (no token)
    if (_token == null) {
      return Scaffold(
        body: Stack(
          children: [
            const GradientBackground(),
            Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Error icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      l10n.invalidResetLink,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      _errorMessage ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade300,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    TextButton(
                      onPressed: () {
                        NavigationService.pushReplacementNamed(AppRoutes.auth);
                      },
                      child: Text(
                        l10n.backToSignIn,
                        style: const TextStyle(
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show password reset form
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
                      onPressed: () => NavigationService.pushReplacementNamed(AppRoutes.auth),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.goldColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: AppTheme.goldColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    l10n.resetYourPassword,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    l10n.enterNewPassword,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade300),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Form
                  FrostedGlass(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // New password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.newPassword,
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.buttonRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.buttonRadius,
                                borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: _validatePassword,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Confirm password field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: l10n.confirmNewPassword,
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.goldColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.buttonRadius,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.buttonRadius,
                                borderSide: const BorderSide(color: AppTheme.goldColor, width: 2),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: _validateConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleResetPassword(),
                          ),

                          const SizedBox(height: 24),

                          GlassButton(
                            text: l10n.resetPassword,
                            onPressed: _handleResetPassword,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Back to sign in link
                  TextButton(
                    onPressed: () => NavigationService.pushReplacementNamed(AppRoutes.auth),
                    child: Text(
                      l10n.backToSignIn,
                      style: TextStyle(
                        color: AppTheme.goldColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
