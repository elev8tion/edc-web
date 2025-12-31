import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/gradient_background.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../features/auth/services/auth_api_service.dart';
import '../features/auth/services/auth_service.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../l10n/app_localizations.dart';

/// Handles email verification from URL token (web only)
///
/// When user clicks the verification link in their email, this screen:
/// 1. Extracts the token from URL query parameters
/// 2. Calls the backend API to verify the email
/// 3. Shows success/error and navigates appropriately
class EmailVerificationHandlerScreen extends ConsumerStatefulWidget {
  const EmailVerificationHandlerScreen({super.key});

  @override
  ConsumerState<EmailVerificationHandlerScreen> createState() =>
      _EmailVerificationHandlerScreenState();
}

class _EmailVerificationHandlerScreenState
    extends ConsumerState<EmailVerificationHandlerScreen> {
  bool _isVerifying = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleVerification();
  }

  Future<void> _handleVerification() async {
    // Extract token from URL query parameters
    final uri = Uri.parse(html.window.location.href);
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'No verification token found';
      });
      return;
    }

    try {
      // Call the verification API
      final response = await AuthApiService().verifyEmail(token: token);

      if (response.success) {
        setState(() {
          _isVerifying = false;
          _isSuccess = true;
        });

        // Re-initialize auth to get the updated user state
        final authService = ref.read(authServiceProvider.notifier);
        await authService.initialize();

        // Wait briefly then navigate to home
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          NavigationService.pushAndRemoveUntilImmediate(AppRoutes.home);
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = response.error ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isSuccess
                          ? Colors.green.withValues(alpha: 0.2)
                          : _errorMessage != null
                              ? Colors.red.withValues(alpha: 0.2)
                              : AppTheme.goldColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isSuccess
                            ? Colors.green.withValues(alpha: 0.5)
                            : _errorMessage != null
                                ? Colors.red.withValues(alpha: 0.5)
                                : AppTheme.goldColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isSuccess
                          ? Icons.check_circle
                          : _errorMessage != null
                              ? Icons.error_outline
                              : Icons.email_outlined,
                      color: _isSuccess
                          ? Colors.green
                          : _errorMessage != null
                              ? Colors.red
                              : AppTheme.goldColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Title
                  Text(
                    _isVerifying
                        ? l10n.verifyingEmail
                        : _isSuccess
                            ? l10n.emailVerified
                            : l10n.verificationFailed,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Subtitle/Error message
                  Text(
                    _isVerifying
                        ? l10n.pleaseWait
                        : _isSuccess
                            ? l10n.redirectingToApp
                            : _errorMessage ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: _errorMessage != null
                          ? Colors.red.shade300
                          : AppColors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Loading indicator or retry button
                  if (_isVerifying)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    )
                  else if (_errorMessage != null)
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
}
