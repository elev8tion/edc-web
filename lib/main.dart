import 'package:everyday_christian/components/app_update_wrapper.dart';
import 'package:everyday_christian/components/offline_indicator.dart';
import 'package:everyday_christian/components/pwa_install_wrapper.dart';
import 'package:everyday_christian/components/storage_consent_banner.dart';
import 'package:everyday_christian/core/config/env_validator.dart';
import 'package:everyday_christian/core/navigation/app_routes.dart';
import 'package:everyday_christian/core/navigation/navigation_service.dart';
import 'package:everyday_christian/core/navigation/page_transitions.dart';
import 'package:everyday_christian/core/providers/app_providers.dart';
import 'package:everyday_christian/core/providers/secure_auth_provider.dart';
import 'package:everyday_christian/core/services/app_update_service.dart';
import 'package:everyday_christian/core/services/pwa_install_service.dart';
import 'package:everyday_christian/core/services/subscription_service.dart';
import 'package:everyday_christian/screens/bible_browser_screen.dart';
import 'package:everyday_christian/screens/chapter_reading_screen.dart';
import 'package:everyday_christian/screens/chat_screen.dart';
import 'package:everyday_christian/screens/devotional_screen.dart';
import 'package:everyday_christian/screens/home_screen.dart';
// Onboarding screen deprecated - legal agreements now in signup form
// import 'package:everyday_christian/screens/unified_interactive_onboarding_screen.dart';
import 'package:everyday_christian/screens/prayer_journal_screen.dart';
import 'package:everyday_christian/screens/profile_screen.dart';
import 'package:everyday_christian/screens/reading_plan_screen.dart';
import 'package:everyday_christian/screens/settings_screen.dart';
import 'package:everyday_christian/screens/splash_screen.dart';
import 'package:everyday_christian/screens/verse_library_screen.dart';
import 'package:everyday_christian/screens/checkout_complete_screen.dart';
import 'package:everyday_christian/screens/auth_screen.dart';
import 'package:everyday_christian/screens/verify_email_screen.dart';
import 'package:everyday_christian/screens/wait_for_verification_screen.dart';
import 'package:everyday_christian/screens/email_verification_handler_screen.dart';
import 'package:everyday_christian/screens/reset_password_screen.dart';
import 'package:everyday_christian/screens/accessibility_statement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:upgrader/upgrader.dart';
import 'l10n/app_localizations.dart';
import 'services/stripe_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge mode for Android 15+ (API 35) compatibility
  // This ensures the app displays correctly with system insets on Android 15
  // and provides backwards compatibility for earlier Android versions
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize timezone database for scheduled notifications
  tz.initializeTimeZones();

  // Set local timezone to device timezone (critical for notifications to fire at correct time)
  // Use UTC as fallback if local timezone detection fails
  try {
    final String timeZoneName = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    // Fallback to UTC if timezone detection fails
    tz.setLocalLocation(tz.UTC);
  }

  // Load environment variables from .env file (mobile only - web uses Cloudflare proxy)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      EnvValidator.validate();
    } catch (e) {
      rethrow;
    }
  }

  // Initialize Stripe for payment processing
  // Uses conditional imports: flutter_stripe on mobile, Embedded Checkout on web
  await initializeStripe();

  final subscriptionService = SubscriptionService.instance;
  await subscriptionService.initialize();

  // Initialize PWA install support (web only)
  // Note: We manually trigger the install prompt after tutorial, so no auto-delay needed
  if (kIsWeb) {
    // Initialize our custom PWA install service early to capture beforeinstallprompt
    final pwaService = PwaInstallService();
    pwaService.initialize();

    FlutterPWAInstall.instance.setup(
      config: const PWAConfig(
        delayPrompt:
            Duration.zero, // No auto-delay - we trigger manually after tutorial
        maxDismissals: 2,
        dismissCooldown: Duration(days: 7),
        showIOSInstructions: true,
        debug: true, // Enable debug to see PWA events in console
      ),
    );

    // Initialize app update service to detect service worker updates
    await AppUpdateService.instance.initialize();

    // Sync subscription status with Stripe on app start
    // This ensures local state matches Stripe (handles cancellations, renewals, etc.)
    // Run async to not block app startup
    subscriptionService.syncWithStripe();

    // Note: Install prompt handling moved to PWAInstallWrapper
    // which shows a dialog when ?install=true is in the URL
  }

  runApp(
    ProviderScope(
      overrides: [
        subscriptionServiceProvider.overrideWithValue(subscriptionService),
      ],
      child: const MyApp(),
    ),
  );
}

/// Navigator observer that prevents back navigation to protected routes after logout
class SecureNavigatorObserver extends NavigatorObserver {
  final WidgetRef ref;

  SecureNavigatorObserver(this.ref);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name != null) {
      final isProtected = AppRoutes.isAuthRequired(previousRoute!.settings.name!);
      final authState = ref.read(secureAuthProvider);

      if (isProtected && authState != SecureAuthState.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.auth,
            (route) => false,
          );
        });
      }
    }
    super.didPop(route, previousRoute);
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(secureAuthProvider.notifier).initialize();
    });
  }

  /// Handle auth state changes for navigation
  void _handleAuthStateChange(SecureAuthState? previous, SecureAuthState current) {
    final navigator = NavigationService.navigatorKey.currentState;
    if (navigator == null) return;

    switch (current) {
      case SecureAuthState.authenticated:
        // If coming from unauthenticated, navigate to home
        if (previous == SecureAuthState.unauthenticated ||
            previous == SecureAuthState.initial) {
          // Check if there's an intended route to restore
          final intendedRoute = NavigationService.consumeIntendedRoute();
          navigator.pushNamedAndRemoveUntil(
            intendedRoute ?? AppRoutes.home,
            (route) => false,
          );
        }
        break;

      case SecureAuthState.unauthenticated:
        // If was authenticated, force to auth screen
        if (previous == SecureAuthState.authenticated) {
          navigator.pushNamedAndRemoveUntil(
            AppRoutes.auth,
            (route) => false,
          );
        }
        break;

      case SecureAuthState.error:
        // Show error notification
        ScaffoldMessenger.of(navigator.context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final locale = ref.watch(languageProvider);

    // Listen to auth state changes
    ref.listen<SecureAuthState>(secureAuthProvider, (previous, current) {
      _handleAuthStateChange(previous, current);
    });

    return MaterialApp(
      title: 'Everyday Christian',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [
        SecureNavigatorObserver(ref),
      ],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) {
        Widget content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textSize),
          ),
          child: OfflineIndicator(child: child!),
        );

        // Wrap with web-specific wrappers for update, install dialogs, and consent banner
        if (kIsWeb) {
          content = AppUpdateWrapper(child: content);
          content = PWAInstallWrapper(child: content);
          content = StorageConsentBanner(child: content);
        }

        return content;
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      // Use initialRoute to properly handle URL-based navigation on web (e.g., /checkout-complete)
      // The WidgetsBinding.platformDispatcher.defaultRouteName returns the URL path on web
      initialRoute: kIsWeb
          ? WidgetsBinding.instance.platformDispatcher.defaultRouteName
          : '/',
      onGenerateRoute: (settings) {
        // Handle root route with platform-specific wrapping
        if (settings.name == '/' || settings.name == '') {
          return DarkPageRoute(
            settings: settings,
            builder: (_) => kIsWeb
                ? const SplashScreen()
                : UpgradeAlert(
                    upgrader: Upgrader(
                      durationUntilAlertAgain: const Duration(days: 3),
                      minAppVersion: '1.0.0',
                    ),
                    child: const SplashScreen(),
                  ),
          );
        }
        switch (settings.name) {
          case AppRoutes.splash:
            return DarkPageRoute(
                settings: settings, builder: (_) => const SplashScreen());
          case AppRoutes.auth:
            return DarkPageRoute(
                settings: settings, builder: (_) => const AuthScreen());
          case AppRoutes.verifyEmail:
            // On web, use the handler screen to process verification token from URL
            if (kIsWeb) {
              return DarkPageRoute(
                settings: settings,
                builder: (_) => const EmailVerificationHandlerScreen(),
              );
            }
            // On mobile, show the verify email screen with email argument
            final args = settings.arguments as Map<String, dynamic>?;
            return DarkPageRoute(
              settings: settings,
              builder: (_) => VerifyEmailScreen(
                email: args?['email'] ?? '',
              ),
            );
          case AppRoutes.resetPassword:
            // Web only: Handle password reset token from email link
            if (kIsWeb) {
              return DarkPageRoute(
                settings: settings,
                builder: (_) => const ResetPasswordScreen(),
              );
            }
            // On mobile, redirect to auth (mobile handles deep links differently)
            return DarkPageRoute(
                settings: settings, builder: (_) => const AuthScreen());
          // Note: Onboarding route removed - legal agreements now in signup form
          // All navigation should go directly to home after verification
          case AppRoutes.waitForVerification:
            return DarkPageRoute(
                settings: settings,
                builder: (_) => const WaitForVerificationScreen());
          // ================================================================
          // PROTECTED ROUTES - Use SecurePageRoute (no caching)
          // These routes require authentication and should not be cached
          // ================================================================
          case AppRoutes.home:
            return SecurePageRoute(
                settings: settings, builder: (_) => const HomeScreen());
          case AppRoutes.chat:
            return SecurePageRoute(
                settings: settings, builder: (_) => const ChatScreen());
          case AppRoutes.settings:
            return SecurePageRoute(
                settings: settings, builder: (_) => const SettingsScreen());
          case AppRoutes.prayerJournal:
            return SecurePageRoute(
                settings: settings,
                builder: (_) => const PrayerJournalScreen());
          case AppRoutes.profile:
            return SecurePageRoute(
                settings: settings, builder: (_) => const ProfileScreen());
          case AppRoutes.devotional:
            return SecurePageRoute(
                settings: settings, builder: (_) => const DevotionalScreen());
          case AppRoutes.readingPlan:
            return SecurePageRoute(
                settings: settings, builder: (_) => const ReadingPlanScreen());
          case AppRoutes.bibleBrowser:
            return SecurePageRoute(
                settings: settings, builder: (_) => const BibleBrowserScreen());
          case AppRoutes.verseLibrary:
            return SecurePageRoute(
                settings: settings, builder: (_) => const VerseLibraryScreen());
          case AppRoutes.chapterReading:
            final args = settings.arguments as Map<String, dynamic>?;
            return SecurePageRoute(
              settings: settings,
              builder: (_) => ChapterReadingScreen(
                book: args?['book'] ?? '',
                startChapter: args?['startChapter'] ?? 1,
                endChapter: args?['endChapter'] ?? 1,
                readingId: args?['readingId'],
              ),
            );
          case AppRoutes.checkoutComplete:
            return DarkPageRoute(
                settings: settings,
                builder: (_) => const CheckoutCompleteScreen());
          case AppRoutes.accessibilityStatement:
            return DarkPageRoute(
                settings: settings,
                builder: (_) => const AccessibilityStatementScreen());
          default:
            return null;
        }
      },
      // Handle unknown routes by redirecting to splash (prevents PWA crash on unknown URLs)
      onUnknownRoute: (settings) {
        return DarkPageRoute(
            settings: settings, builder: (_) => const SplashScreen());
      },
    );
  }
}
