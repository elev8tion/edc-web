import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_scalify/flutter_scalify.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/widgets/auth_form.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../components/animations/blur_fade.dart';
import '../components/glass/static_liquid_glass_lens.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../utils/responsive_utils.dart';
import '../core/widgets/app_snackbar.dart';
import '../l10n/app_localizations.dart';

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
        authenticated: (user) {
          // Navigate to home on successful authentication
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
          AppWidthLimiter(
            maxWidth: 600,
            horizontalPadding: 0,
            backgroundColor: Colors.transparent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.s),
                child: Column(
                  children: [
                    AppSpacing.xl.sbh,

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
                        AppSpacing.lg.sbh,
                        Text(
                          l10n.welcomeBack,
                          style: TextStyle(
                            fontSize: 28.fz,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        AppSpacing.sm.sbh,
                        Text(
                          l10n.signInToContinue,
                          style: TextStyle(
                            fontSize: 16.fz,
                            color: AppColors.secondaryText,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.xxl.sbh,

                  // Auth form
                  BlurFade(
                    delay: const Duration(milliseconds: 300),
                    isVisible: _showContent,
                    child: const AuthForm(),
                  ),

                  AppSpacing.xl.sbh,

                  // Privacy note
                  Text(
                    l10n.privacyNote,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12.fz,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
