import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/widgets/auth_form.dart';
import '../components/gradient_background.dart';
import '../components/animations/blur_fade.dart';
import '../components/glass/static_liquid_glass_lens.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../core/navigation/page_transitions.dart';
import '../core/services/preferences_service.dart';
import '../utils/responsive_utils.dart';
import '../core/widgets/app_snackbar.dart';
import '../l10n/app_localizations.dart';
import 'forgot_password_screen.dart';
import '../theme/app_theme_extensions.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showContent = false;
  final GlobalKey _backgroundKey = GlobalKey();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Guard against double initialization
    if (_hasInitialized) return;
    _hasInitialized = true;

    // Show content with slight delay for smooth appearance
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showContent = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authServiceProvider, (previous, next) {
      next.when(
        initial: () {},
        loading: () {},
        authenticated: (user) async {
          // Check the user's state to determine navigation
          if (user.isNewUser && !user.isEmailVerified) {
            // New signup - wait for email verification
            NavigationService.pushAndRemoveUntil(AppRoutes.waitForVerification);
            return;
          }

          // Check if onboarding is completed
          final prefsService = await PreferencesService.getInstance();
          final hasCompletedOnboarding = prefsService.hasCompletedOnboarding();

          if (!hasCompletedOnboarding) {
            // User needs to complete onboarding
            NavigationService.pushAndRemoveUntil(AppRoutes.onboarding);
            return;
          }

          // All checks passed - go to home
          NavigationService.pushAndRemoveUntil(AppRoutes.home);
        },
        unauthenticated: () {},
        error: (message) {
          if (!mounted) return;
          AppSnackBar.showError(context, message: message);
        },
      );
    });

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: _backgroundKey,
            child: const GradientBackground(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Liquid glass logo section
                  BlurFade(
                    delay: const Duration(milliseconds: 100),
                    isVisible: _showContent,
                    child: Column(
                      children: [
                        StaticLiquidGlassLens(
                          backgroundKey: _backgroundKey,
                          width: 200,
                          height: 200,
                          effectSize: 3.0,
                          dispersionStrength: 0.3,
                          blurIntensity: 0.05,
                          child: Image.asset(
                            'assets/images/logo_transparent.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.welcomeBack,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 28, minSize: 24, maxSize: 32),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.signInToContinue,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                            color: AppColors.secondaryText,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Auth form
                  BlurFade(
                    delay: const Duration(milliseconds: 300),
                    isVisible: _showContent,
                    child: AuthForm(
                      onForgotPassword: () {
                        Navigator.of(context).push(
                          DarkPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
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
