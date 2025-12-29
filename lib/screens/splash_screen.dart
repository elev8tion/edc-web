import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../components/glass_card.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../core/widgets/app_initializer.dart';
import '../core/services/preferences_service.dart';
import '../core/providers/app_providers.dart';
import '../hooks/animation_hooks.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  // Static flag to prevent double navigation
  static bool _hasNavigated = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Reset navigation flag on first build
    useEffect(() {
      _hasNavigated = false;
      return null;
    }, []);

    // Use custom hook for combined fade and scale animations
    final animations = useFadeAndScale(
      fadeDuration: const Duration(milliseconds: 1500),
      scaleDuration: const Duration(milliseconds: 2000),
    );

    // Create animations with curves
    final fadeAnimation = useAnimation(
      CurvedAnimation(
        parent: animations.fade,
        curve: Curves.easeInOut,
      ),
    );

    final scaleAnimation = useAnimation(
      CurvedAnimation(
        parent: animations.scale,
        curve: Curves.elasticOut,
      ),
    );

    // Watch app initialization and navigate when ready (no more timer!)
    final initializationAsync = ref.watch(appInitializationProvider);

    // Get current route BEFORE useEffect (outside of initialization)
    final currentRoute = ModalRoute.of(context)?.settings.name;

    useEffect(() {
      // Guard against double navigation
      if (_hasNavigated) return null;

      // Only navigate when initialization completes successfully
      initializationAsync.whenData((_) async {
        if (_hasNavigated) return;

        // Check if we're still on splash screen before navigating
        // On web, currentRoute may be null - allow navigation in that case
        if (currentRoute != null && currentRoute != AppRoutes.splash && currentRoute != '/') return;

        // Check if user has completed onboarding (which now includes legal agreements)
        final prefsService = await PreferencesService.getInstance();
        final hasCompletedOnboarding = prefsService.hasCompletedOnboarding();

        if (!hasCompletedOnboarding) {
          // First time user - show unified interactive onboarding
          if (_hasNavigated) return;
          _hasNavigated = true;
          NavigationService.pushReplacementNamed(AppRoutes.onboarding);
          return;
        }

        // Returning user - check if app lock is enabled (skip on web)
        if (!kIsWeb) {
          final isAppLockEnabled = prefsService.isAppLockEnabled();

          if (isAppLockEnabled) {
            // App lock is enabled - show custom app lock screen (mobile only)
            if (_hasNavigated) return;
            _hasNavigated = true;
            // App lock not available on web - go to home instead
            NavigationService.pushReplacementNamed(AppRoutes.home);
            return;
          }
        }

        // Go directly to home
        if (_hasNavigated) return;
        _hasNavigated = true;
        NavigationService.pushReplacementNamed(AppRoutes.home);
      });

      return null;
    }, [initializationAsync]);

    // Wrap the splash screen UI with AppInitializer
    return AppInitializer(
      child: Scaffold(
        body: Stack(
          children: [
            // Existing gradient background
            const GradientBackground(),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: AlwaysStoppedAnimation(fadeAnimation),
                  child: ScaleTransition(
                    scale: AlwaysStoppedAnimation(scaleAnimation),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with FAB menu style
                        Semantics(
                          label: l10n.appLogo,
                          image: true,
                          child: GlassContainer(
                            width: 200,
                            height: 200,
                            padding: const EdgeInsets.all(16.0),
                            borderRadius: 40,
                            blurStrength: 15.0,
                            gradientColors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                            border: Border.all(
                              color: AppTheme.goldColor,
                              width: 2.0,
                            ),
                            child: Center(
                              child: Image.asset(
                                Localizations.localeOf(context).languageCode == 'es'
                                    ? 'assets/images/logo_spanish.png'
                                    : 'assets/images/logo_cropped.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.church,
                                    color: Colors.white,
                                    size: 100,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // App name (clean, no card)
                        Text(
                          l10n.appName,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 26, minSize: 22, maxSize: 30),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8,
                            color: AppTheme.goldColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appNameSecond,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 36, minSize: 32, maxSize: 40),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppColors.primaryText,
                          ),
                        ),

                        const SizedBox(height: 80),

                        // Simple loading indicator
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.goldColor,
                            ),
                            strokeWidth: 3,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Loading text (simplified)
                        Text(
                          l10n.loadingJourney,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 16, minSize: 14, maxSize: 18),
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom branding
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: AlwaysStoppedAnimation(fadeAnimation),
                child: Column(
                  children: [
                    Text(
                      l10n.version,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: AppColors.secondaryText.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.builtWithFaith,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: AppColors.secondaryText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
