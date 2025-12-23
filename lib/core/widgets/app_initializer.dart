import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../error/app_error.dart';
import '../services/preferences_service.dart';
import '../../components/gradient_background.dart';
import '../../components/dancing_logo_loader.dart';
import '../../components/glass_card.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AppInitializer extends ConsumerWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initializationAsync = ref.watch(appInitializationProvider);

    return initializationAsync.when(
      data: (_) => child,
      loading: () => const _LoadingScreen(),
      error: (error, stack) => _ErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(appInitializationProvider),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Center(
              child: FutureBuilder<PreferencesService>(
                future: PreferencesService.getInstance(),
                builder: (context, snapshot) {
                  final languageCode = snapshot.hasData
                      ? snapshot.data!.getLanguage()
                      : 'en';

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with FAB menu style
                      GlassContainer(
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
                            languageCode == 'es'
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

                  const SizedBox(height: 32),

                  // App name (localized)
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appNameSecond,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Dancing logo loader (180px, 3s - default values)
                  DancingLogoLoader(
                    languageCode: languageCode,
                  ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = error is AppError
        ? (error as AppError).message
        : 'An unexpected error occurred';

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Initialization Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Retry'),
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
