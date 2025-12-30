import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/services/auth_service.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass.dart';
import '../components/glass_button.dart';
import '../core/widgets/app_snackbar.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isLoading = false;
  bool _isCheckingVerification = false;

  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider.notifier);
    final success = await authService.resendVerification(email: widget.email);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).verificationEmailSent,
        );
      } else {
        AppSnackBar.showError(
          context,
          message: AppLocalizations.of(context).verificationEmailError,
        );
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isCheckingVerification = true);

    final authService = ref.read(authServiceProvider.notifier);
    await authService.initialize();

    setState(() => _isCheckingVerification = false);

    final authState = ref.read(authServiceProvider);
    final isAuthenticated = authState.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (mounted && isAuthenticated) {
      // User is now verified, go to onboarding or home
      NavigationService.pushReplacementNamed(AppRoutes.onboarding);
    } else if (mounted) {
      AppSnackBar.showError(
        context,
        message: AppLocalizations.of(context).verificationEmailError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      onPressed: () => Navigator.of(context).pop(),
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
                      Icons.mark_email_unread,
                      color: AppTheme.goldColor,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    l10n.verifyYourEmail,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle with email address
                  Text(
                    l10n.verifyEmailSubtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Email display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: AppRadius.cardRadius,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: AppTheme.goldColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Action buttons
                  FrostedGlass(
                    child: Column(
                      children: [
                        GlassButton(
                          text: l10n.alreadyVerified,
                          onPressed: _checkVerificationStatus,
                          isLoading: _isCheckingVerification,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GlassButton(
                          text: l10n.resendVerificationEmail,
                          onPressed: _resendVerificationEmail,
                          isLoading: _isLoading,
                          borderColor: AppTheme.goldColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
