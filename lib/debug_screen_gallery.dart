import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';

// Import all duplicate screens
import 'screens/chat_screen.dart' as screens_chat;
// import 'features/chat/screens/chat_screen.dart' as features_chat; // Path doesn't exist
import 'screens/home_screen.dart';
import 'screens/prayer_journal_screen.dart';
import 'screens/verse_library_screen.dart';
import 'screens/devotional_screen.dart';
import 'screens/reading_plan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

class DebugScreenGallery extends ConsumerStatefulWidget {
  const DebugScreenGallery({super.key});

  @override
  ConsumerState<DebugScreenGallery> createState() => _DebugScreenGalleryState();
}

class _DebugScreenGalleryState extends ConsumerState<DebugScreenGallery> {
  int currentIndex = 0;

  final List<ScreenInfo> screens = [
    ScreenInfo(
      title: 'Chat Screen',
      description: 'lib/screens/chat_screen.dart',
      widget: const screens_chat.ChatScreen(),
    ),
    // ScreenInfo(
    //   title: 'DUPLICATE: Chat Screen (features/)',
    //   description: 'lib/features/chat/screens/chat_screen.dart',
    //   widget: features_chat.ChatScreen(),
    // ),
    ScreenInfo(
      title: 'Home Screen',
      description: 'lib/screens/home_screen.dart',
      widget: const HomeScreen(),
    ),
    ScreenInfo(
      title: 'Prayer Journal Screen',
      description: 'lib/screens/prayer_journal_screen.dart',
      widget: const PrayerJournalScreen(),
    ),
    ScreenInfo(
      title: 'Verse Library Screen',
      description: 'lib/screens/verse_library_screen.dart',
      widget: const VerseLibraryScreen(),
    ),
    ScreenInfo(
      title: 'Devotional Screen',
      description: 'lib/screens/devotional_screen.dart',
      widget: const DevotionalScreen(),
    ),
    ScreenInfo(
      title: 'Reading Plan Screen',
      description: 'lib/screens/reading_plan_screen.dart',
      widget: const ReadingPlanScreen(),
    ),
    ScreenInfo(
      title: 'Settings Screen',
      description: 'lib/screens/settings_screen.dart',
      widget: const SettingsScreen(),
    ),
    ScreenInfo(
      title: 'Profile Screen',
      description: 'lib/screens/profile_screen.dart',
      widget: const ProfileScreen(),
    ),
    ScreenInfo(
      title: 'Auth Screen',
      description: 'lib/screens/auth_screen.dart',
      widget: const AuthScreen(),
    ),
    ScreenInfo(
      title: 'Onboarding Screen',
      description: 'lib/screens/onboarding_screen.dart',
      widget: const OnboardingScreen(),
    ),
    ScreenInfo(
      title: 'Splash Screen',
      description: 'lib/screens/splash_screen.dart',
      widget: const SplashScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Current screen
          screens[currentIndex].widget,

          // Overlay with navigation and identification
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: AppRadius.mediumRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    screens[currentIndex].title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    screens[currentIndex].description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Screen ${currentIndex + 1} of ${screens.length}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: IconButton(
                    onPressed: currentIndex > 0 ? _previousScreen : null,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Forward button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: AppRadius.smallRadius,
                  ),
                  child: IconButton(
                    onPressed: currentIndex < screens.length - 1 ? _nextScreen : null,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close gallery button
          Positioned(
            top: 120,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: AppRadius.smallRadius,
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousScreen() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _nextScreen() {
    if (currentIndex < screens.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }
}

class ScreenInfo {
  final String title;
  final String description;
  final Widget widget;

  ScreenInfo({
    required this.title,
    required this.description,
    required this.widget,
  });
}