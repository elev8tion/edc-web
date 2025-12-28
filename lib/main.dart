import 'package:everyday_christian/components/app_update_wrapper.dart';
import 'package:everyday_christian/components/offline_indicator.dart';
import 'package:everyday_christian/components/pwa_install_wrapper.dart';
import 'package:everyday_christian/core/config/env_validator.dart';
import 'package:everyday_christian/core/navigation/app_routes.dart';
import 'package:everyday_christian/core/navigation/navigation_service.dart';
import 'package:everyday_christian/core/providers/app_providers.dart';
import 'package:everyday_christian/core/services/app_update_service.dart';
import 'package:everyday_christian/core/services/subscription_service.dart';
import 'package:everyday_christian/screens/bible_browser_screen.dart';
import 'package:everyday_christian/screens/chapter_reading_screen.dart';
import 'package:everyday_christian/screens/chat_screen.dart';
import 'package:everyday_christian/screens/devotional_screen.dart';
import 'package:everyday_christian/screens/home_screen.dart';
import 'package:everyday_christian/screens/unified_interactive_onboarding_screen.dart';
import 'package:everyday_christian/screens/prayer_journal_screen.dart';
import 'package:everyday_christian/screens/profile_screen.dart';
import 'package:everyday_christian/screens/reading_plan_screen.dart';
import 'package:everyday_christian/screens/settings_screen.dart';
import 'package:everyday_christian/screens/splash_screen.dart';
import 'package:everyday_christian/screens/verse_library_screen.dart';
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

  // Load environment variables from .env file (skip on web if file doesn't exist)
  try {
    await dotenv.load(fileName: ".env");

    // Validate environment configuration (security check)
    // This will throw EnvValidationException if any issues are found
    EnvValidator.validate();
  } catch (e) {
    // .env file not found - continue without it (web deployment)
    if (kIsWeb) {
      // On web, env vars are typically set at build time or in environment
      debugPrint('[main] .env file not found on web - continuing without it');
    } else {
      rethrow;
    }
  }

  final subscriptionService = SubscriptionService.instance;
  await subscriptionService.initialize();

  // Initialize PWA install support (web only)
  // Note: We manually trigger the install prompt after tutorial, so no auto-delay needed
  if (kIsWeb) {
    FlutterPWAInstall.instance.setup(
      config: const PWAConfig(
        delayPrompt: Duration.zero, // No auto-delay - we trigger manually after tutorial
        maxDismissals: 2,
        dismissCooldown: Duration(days: 7),
        showIOSInstructions: true,
        debug: true, // Enable debug to see PWA events in console
      ),
    );

    // Initialize app update service to detect service worker updates
    await AppUpdateService.instance.initialize();

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

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(textSizeProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Everyday Christian',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
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

        // Wrap with web-specific wrappers for update and install dialogs
        if (kIsWeb) {
          content = AppUpdateWrapper(child: content);
          content = PWAInstallWrapper(child: content);
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
      // Upgrader not supported on web - skip for web platform
      home: kIsWeb
          ? const SplashScreen()
          : UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: const Duration(days: 3),
                minAppVersion: '1.0.0',
              ),
              child: const SplashScreen(),
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const UnifiedInteractiveOnboardingScreen());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case AppRoutes.chat:
            return MaterialPageRoute(builder: (_) => const ChatScreen());
          case AppRoutes.settings:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case AppRoutes.prayerJournal:
            return MaterialPageRoute(builder: (_) => const PrayerJournalScreen());
          case AppRoutes.profile:
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case AppRoutes.devotional:
            return MaterialPageRoute(builder: (_) => const DevotionalScreen());
          case AppRoutes.readingPlan:
            return MaterialPageRoute(builder: (_) => const ReadingPlanScreen());
          case AppRoutes.bibleBrowser:
            return MaterialPageRoute(builder: (_) => const BibleBrowserScreen());
          case AppRoutes.verseLibrary:
            return MaterialPageRoute(builder: (_) => const VerseLibraryScreen());
          case AppRoutes.chapterReading:
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ChapterReadingScreen(
                book: args?['book'] ?? '',
                startChapter: args?['startChapter'] ?? 1,
                endChapter: args?['endChapter'] ?? 1,
                readingId: args?['readingId'],
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
