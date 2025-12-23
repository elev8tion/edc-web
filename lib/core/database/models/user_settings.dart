class UserSettings {
  final String key;
  final dynamic value;
  final String type;
  final DateTime updatedAt;

  const UserSettings({
    required this.key,
    required this.value,
    required this.type,
    required this.updatedAt,
  });

  /// Create UserSettings from database map
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      key: map['key'] as String,
      value: _parseValue(map['value'] as String, map['type'] as String),
      type: map['type'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert UserSettings to database map
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value.toString(),
      'type': type,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Parse value based on type
  static dynamic _parseValue(String value, String type) {
    switch (type) {
      case 'bool':
        return value.toLowerCase() == 'true';
      case 'int':
        return int.tryParse(value) ?? 0;
      case 'double':
        return double.tryParse(value) ?? 0.0;
      case 'String':
      default:
        return value;
    }
  }

  @override
  String toString() {
    return 'UserSettings(key: $key, value: $value, type: $type)';
  }
}

/// Settings keys constants
class SettingsKeys {
  // Daily verse settings
  static const String dailyVerseTime = 'daily_verse_time';
  static const String dailyVerseEnabled = 'daily_verse_enabled';
  static const String preferredTranslation = 'preferred_translation';
  static const String preferredVerseThemes = 'preferred_verse_themes';
  static const String verseStreakCount = 'verse_streak_count';
  static const String lastVerseDate = 'last_verse_date';

  // App appearance
  static const String themeMode = 'theme_mode'; // light, dark, system
  static const String fontSizeScale = 'font_size_scale';

  // Notifications
  static const String notificationsEnabled = 'notifications_enabled';
  static const String prayerReminderEnabled = 'prayer_reminder_enabled';

  // Security
  static const String biometricEnabled = 'biometric_enabled';

  // Data management
  static const String chatHistoryDays = 'chat_history_days';

  // Onboarding
  static const String onboardingCompleted = 'onboarding_completed';
  static const String firstLaunch = 'first_launch';

  // All settings keys
  static const List<String> allKeys = [
    dailyVerseTime,
    dailyVerseEnabled,
    preferredTranslation,
    preferredVerseThemes,
    verseStreakCount,
    lastVerseDate,
    themeMode,
    fontSizeScale,
    notificationsEnabled,
    prayerReminderEnabled,
    biometricEnabled,
    chatHistoryDays,
    onboardingCompleted,
    firstLaunch,
  ];
}

/// Settings helper class for type-safe operations
class AppSettings {
  // Daily verse settings
  static const String defaultDailyVerseTime = '09:30';
  static const bool defaultDailyVerseEnabled = true;
  static const String defaultPreferredTranslation = 'ESV';
  static const List<String> defaultPreferredThemes = ['hope', 'strength', 'comfort'];

  // Theme settings
  static const String defaultThemeMode = 'system';
  static const double defaultFontSizeScale = 1.0;

  // Notification settings
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultPrayerReminderEnabled = true;

  // Security settings
  static const bool defaultBiometricEnabled = false;

  // Data settings
  static const int defaultChatHistoryDays = 30;

  // Onboarding settings
  static const bool defaultOnboardingCompleted = false;
  static const bool defaultFirstLaunch = true;

  /// Get default value for a setting key
  static dynamic getDefaultValue(String key) {
    switch (key) {
      case SettingsKeys.dailyVerseTime:
        return defaultDailyVerseTime;
      case SettingsKeys.dailyVerseEnabled:
        return defaultDailyVerseEnabled;
      case SettingsKeys.preferredTranslation:
        return defaultPreferredTranslation;
      case SettingsKeys.preferredVerseThemes:
        return defaultPreferredThemes;
      case SettingsKeys.verseStreakCount:
        return 0;
      case SettingsKeys.lastVerseDate:
        return 0;
      case SettingsKeys.themeMode:
        return defaultThemeMode;
      case SettingsKeys.fontSizeScale:
        return defaultFontSizeScale;
      case SettingsKeys.notificationsEnabled:
        return defaultNotificationsEnabled;
      case SettingsKeys.prayerReminderEnabled:
        return defaultPrayerReminderEnabled;
      case SettingsKeys.biometricEnabled:
        return defaultBiometricEnabled;
      case SettingsKeys.chatHistoryDays:
        return defaultChatHistoryDays;
      case SettingsKeys.onboardingCompleted:
        return defaultOnboardingCompleted;
      case SettingsKeys.firstLaunch:
        return defaultFirstLaunch;
      default:
        return null;
    }
  }

  /// Get setting display name
  static String getDisplayName(String key) {
    switch (key) {
      case SettingsKeys.dailyVerseTime:
        return 'Daily Verse Time';
      case SettingsKeys.dailyVerseEnabled:
        return 'Daily Verse Notifications';
      case SettingsKeys.preferredTranslation:
        return 'Preferred Bible Translation';
      case SettingsKeys.preferredVerseThemes:
        return 'Preferred Verse Themes';
      case SettingsKeys.themeMode:
        return 'App Theme';
      case SettingsKeys.fontSizeScale:
        return 'Font Size';
      case SettingsKeys.notificationsEnabled:
        return 'Notifications';
      case SettingsKeys.prayerReminderEnabled:
        return 'Prayer Reminders';
      case SettingsKeys.biometricEnabled:
        return 'Biometric Authentication';
      case SettingsKeys.chatHistoryDays:
        return 'Chat History Retention';
      default:
        return key.replaceAll('_', ' ').split(' ').map((word) =>
          word.substring(0, 1).toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  /// Get setting description
  static String getDescription(String key) {
    switch (key) {
      case SettingsKeys.dailyVerseTime:
        return 'Time to receive your daily Bible verse';
      case SettingsKeys.dailyVerseEnabled:
        return 'Receive daily Bible verse notifications';
      case SettingsKeys.preferredTranslation:
        return 'Your preferred Bible translation for verses';
      case SettingsKeys.preferredVerseThemes:
        return 'Types of verses you\'d like to receive';
      case SettingsKeys.themeMode:
        return 'Choose between light, dark, or system theme';
      case SettingsKeys.fontSizeScale:
        return 'Adjust text size throughout the app';
      case SettingsKeys.notificationsEnabled:
        return 'Enable or disable all notifications';
      case SettingsKeys.prayerReminderEnabled:
        return 'Get reminders for your prayer requests';
      case SettingsKeys.biometricEnabled:
        return 'Use fingerprint or face ID to secure the app';
      case SettingsKeys.chatHistoryDays:
        return 'How long to keep your chat conversations';
      default:
        return 'App setting';
    }
  }
}

/// Available Bible translations
class BibleTranslations {
  static const String esv = 'ESV';
  static const String niv = 'NIV';
  static const String nasb = 'NASB';
  static const String kjv = 'WEB';
  static const String nlt = 'NLT';
  static const String csb = 'CSB';
  static const String msg = 'MSG';

  static const List<String> all = [esv, niv, nasb, kjv, nlt, csb, msg];

  static String getFullName(String translation) {
    switch (translation) {
      case esv:
        return 'English Standard Version';
      case niv:
        return 'New International Version';
      case nasb:
        return 'New American Standard Bible';
      case kjv:
        return 'King James Version';
      case nlt:
        return 'New Living Translation';
      case csb:
        return 'Christian Standard Bible';
      case msg:
        return 'The Message';
      default:
        return translation;
    }
  }
}

/// Theme mode options
enum ThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const ThemeMode(this.value);

  final String value;

  static ThemeMode fromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}