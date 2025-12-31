import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/gradient_background.dart';
import '../components/glass_button.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../features/auth/services/auth_service.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/app_snackbar.dart';

class WaitForVerificationScreen extends ConsumerStatefulWidget {
  const WaitForVerificationScreen({super.key});

  @override
  ConsumerState<WaitForVerificationScreen> createState() =>
      _WaitForVerificationScreenState();
}

class _WaitForVerificationScreenState
    extends ConsumerState<WaitForVerificationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Periodically check verification status every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final authService = ref.read(authServiceProvider.notifier);

      // Refresh user data from backend to get latest verification status
      await authService.refreshUser();

      // Check if email is now verified
      final isVerified = authService.isEmailVerified();
      if (isVerified) {
        timer.cancel();
        if (mounted) {
          NavigationService.pushAndRemoveUntilImmediate(AppRoutes.home);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    final l10n = AppLocalizations.of(context);
    final authService = ref.read(authServiceProvider.notifier);
    final user = ref.read(currentUserProvider);

    if (user?.email != null) {
      final success = await authService.resendVerification(email: user!.email!);
      if (mounted) {
        if (success) {
          AppSnackBar.show(context, message: l10n.verificationEmailSent);
        } else {
          AppSnackBar.showError(context, message: l10n.somethingWentWrong);
        }
      }
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider.notifier);
    await authService.signOut();
    if (mounted) {
      NavigationService.pushAndRemoveUntilImmediate(AppRoutes.auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: AppTheme.goldColor,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.verifyYourEmail,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${l10n.checkYourEmail}\n${user?.email ?? ''}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondaryText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  GlassButton(
                    text: l10n.resendVerificationEmail,
                    onPressed: _resendVerificationEmail,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      l10n.signOut,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
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
