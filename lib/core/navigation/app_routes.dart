class AppRoutes {
  static const String splash = '/splash';
  static const String legalAgreements = '/legal-agreements';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String prayerJournal = '/prayer-journal';
  static const String verseLibrary = '/verse-library';
  static const String profile = '/profile';
  static const String devotional = '/devotional';
  static const String readingPlan = '/reading-plan';
  static const String chapterReading = '/chapter-reading';
  static const String bibleBrowser = '/bible-browser';

  static const List<String> authRequiredRoutes = [
    home,
    chat,
    settings,
    prayerJournal,
    verseLibrary,
    profile,
    devotional,
    readingPlan,
    chapterReading,
    bibleBrowser,
  ];

  static const List<String> publicRoutes = [
    splash,
    legalAgreements,
    onboarding,
    auth,
  ];

  static bool isAuthRequired(String route) {
    return authRequiredRoutes.contains(route);
  }

  static bool isPublicRoute(String route) {
    return publicRoutes.contains(route);
  }
}