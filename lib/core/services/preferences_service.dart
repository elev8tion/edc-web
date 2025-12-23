import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences using SharedPreferences
///
/// This service provides type-safe methods for storing and retrieving
/// user settings like theme mode, language preference, and text size.
class PreferencesService {
  // Singleton pattern
  static PreferencesService? _instance;
  static SharedPreferences? _preferences;

  // Private constructor
  PreferencesService._();

  /// Get the singleton instance
  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Initialize SharedPreferences
  Future<void> _init() async {
    try {
      _preferences = await SharedPreferences.getInstance();
    } catch (e) {
      rethrow;
    }
  }

  /// Access the underlying SharedPreferences instance
  SharedPreferences? get prefs => _preferences;

  // Keys for stored preferences
  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language_preference';
  static const String _textSizeKey = 'text_size';
  static const String _firstNameKey = 'user_first_name';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _dailyNotificationsKey = 'daily_notifications_enabled';
  static const String _prayerRemindersKey = 'prayer_reminders_enabled';
  static const String _verseOfTheDayKey = 'verse_of_the_day_enabled';
  static const String _readingPlanRemindersKey = 'reading_plan_reminders_enabled';
  static const String _notificationTimeKey = 'notification_time'; // Legacy - kept for migration
  static const String _devotionalTimeKey = 'devotional_notification_time';
  static const String _prayerTimeKey = 'prayer_notification_time';
  static const String _verseTimeKey = 'verse_notification_time';
  static const String _readingPlanTimeKey = 'reading_plan_notification_time';
  static const String _termsAcceptedKey = 'terms_accepted_v1.0';
  static const String _legalAgreementsKey = 'legal_agreements_accepted_v1.0';
  static const String _fabTutorialShownKey = 'fab_tutorial_shown';
  static const String _verseTutorialShownKey = 'verse_tutorial_shown';
  static const String _prayerTutorialShownKey = 'prayer_tutorial_shown';
  static const String _bibleBrowserTutorialShownKey = 'bible_browser_tutorial_shown';
  static const String _devotionalVerseTutorialShownKey = 'devotional_verse_tutorial_shown';
  static const String _chatTutorialShownKey = 'chat_tutorial_shown';
  static const String _readingPlanTutorialShownKey = 'reading_plan_tutorial_shown';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _biometricSetupCompletedKey = 'biometric_setup_completed';

  // Default values
  static const String _defaultThemeMode = 'dark';
  static const String _defaultLanguage = 'English';
  static const double _defaultTextSize = 1.0; // Scale factor (1.0 = 100%)
  static const bool _defaultNotificationsEnabled = true;
  static const String _defaultNotificationTime = '08:00'; // 8:00 AM
  static const String _defaultDevotionalTime = '07:00'; // 7:00 AM
  static const String _defaultPrayerTime = '12:00'; // 12:00 PM
  static const String _defaultVerseTime = '09:00'; // 9:00 AM
  static const String _defaultReadingPlanTime = '20:00'; // 8:00 PM

  // ============================================================================
  // THEME MODE METHODS
  // ============================================================================

  /// Save theme mode to preferences
  ///
  /// Converts ThemeMode enum to string for storage.
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveThemeMode(ThemeMode mode) async {
    try {
      final String modeString = _themeModeToString(mode);
      final result = await _preferences?.setString(_themeModeKey, modeString);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load theme mode from preferences
  ///
  /// Returns saved ThemeMode or defaults to ThemeMode.dark if not found.
  ThemeMode loadThemeMode() {
    try {
      final String? modeString = _preferences?.getString(_themeModeKey);
      if (modeString == null) {
        return _stringToThemeMode(_defaultThemeMode);
      }
      return _stringToThemeMode(modeString);
    } catch (e) {
      return _stringToThemeMode(_defaultThemeMode);
    }
  }

  /// Convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode
  ThemeMode _stringToThemeMode(String modeString) {
    switch (modeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  // ============================================================================
  // LANGUAGE PREFERENCE METHODS
  // ============================================================================

  /// Save language preference to preferences
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveLanguage(String language) async {
    try {
      final result = await _preferences?.setString(_languageKey, language);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load language preference from preferences
  ///
  /// Returns saved language or defaults to 'English' if not found.
  String loadLanguage() {
    try {
      final String? language = _preferences?.getString(_languageKey);
      if (language == null) {
        return _defaultLanguage;
      }
      return language;
    } catch (e) {
      return _defaultLanguage;
    }
  }

  /// Alias for loadLanguage() - returns language code (e.g., 'en', 'es')
  ///
  /// Converts full language name to language code.
  String getLanguage() {
    final language = loadLanguage();
    // Convert full language name to code
    switch (language.toLowerCase()) {
      case 'english':
        return 'en';
      case 'spanish':
        return 'es';
      default:
        return language.length > 2 ? 'en' : language;
    }
  }

  /// Alias for saveLanguage() - accepts language code (e.g., 'en', 'es')
  ///
  /// Converts language code to full language name before saving.
  Future<bool> setLanguage(String languageCode) async {
    // Convert code to full language name
    String language;
    switch (languageCode.toLowerCase()) {
      case 'en':
        language = 'English';
        break;
      case 'es':
        language = 'Spanish';
        break;
      default:
        language = languageCode;
    }
    return await saveLanguage(language);
  }

  // ============================================================================
  // TEXT SIZE METHODS
  // ============================================================================

  /// Save text size to preferences
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveTextSize(double size) async {
    try {
      final result = await _preferences?.setDouble(_textSizeKey, size);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load text size from preferences
  ///
  /// Returns saved text size scale factor or defaults to 1.0 (100%) if not found.
  double loadTextSize() {
    try {
      final double? size = _preferences?.getDouble(_textSizeKey);
      if (size == null) {
        return _defaultTextSize;
      }
      return size;
    } catch (e) {
      return _defaultTextSize;
    }
  }

  // ============================================================================
  // FIRST NAME METHODS
  // ============================================================================

  /// Save user's first name to preferences
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveFirstName(String firstName) async {
    try {
      final result = await _preferences?.setString(_firstNameKey, firstName);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load user's first name from preferences
  ///
  /// Returns saved first name or null if not set.
  String? loadFirstName() {
    try {
      return _preferences?.getString(_firstNameKey);
    } catch (e) {
      return null;
    }
  }

  /// Get user's first name or "friend" as default greeting
  ///
  /// Returns saved first name or "friend" if not set.
  String getFirstNameOrDefault() {
    final firstName = loadFirstName();
    return firstName?.trim().isEmpty == true || firstName == null
        ? 'friend'
        : firstName;
  }

  /// Delete user's first name from preferences
  ///
  /// Returns true if deletion was successful, false otherwise.
  Future<bool> deleteFirstName() async {
    try {
      final result = await _preferences?.remove(_firstNameKey);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // ONBOARDING COMPLETION METHODS
  // ============================================================================

  /// Mark onboarding as completed
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setOnboardingCompleted() async {
    try {
      final result = await _preferences?.setBool(_onboardingCompletedKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has completed onboarding
  ///
  /// Returns true if onboarding is completed, false otherwise.
  bool hasCompletedOnboarding() {
    try {
      return _preferences?.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // NOTIFICATION SETTINGS METHODS
  // ============================================================================

  /// Save daily notifications enabled status
  Future<bool> saveDailyNotificationsEnabled(bool enabled) async {
    try {
      final result = await _preferences?.setBool(_dailyNotificationsKey, enabled);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load daily notifications enabled status
  bool loadDailyNotificationsEnabled() {
    try {
      final bool? enabled = _preferences?.getBool(_dailyNotificationsKey);
      return enabled ?? _defaultNotificationsEnabled;
    } catch (e) {
      return _defaultNotificationsEnabled;
    }
  }

  /// Save prayer reminders enabled status
  Future<bool> savePrayerRemindersEnabled(bool enabled) async {
    try {
      final result = await _preferences?.setBool(_prayerRemindersKey, enabled);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load prayer reminders enabled status
  bool loadPrayerRemindersEnabled() {
    try {
      final bool? enabled = _preferences?.getBool(_prayerRemindersKey);
      return enabled ?? _defaultNotificationsEnabled;
    } catch (e) {
      return _defaultNotificationsEnabled;
    }
  }

  /// Save verse of the day enabled status
  Future<bool> saveVerseOfTheDayEnabled(bool enabled) async {
    try {
      final result = await _preferences?.setBool(_verseOfTheDayKey, enabled);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load verse of the day enabled status
  bool loadVerseOfTheDayEnabled() {
    try {
      final bool? enabled = _preferences?.getBool(_verseOfTheDayKey);
      return enabled ?? _defaultNotificationsEnabled;
    } catch (e) {
      return _defaultNotificationsEnabled;
    }
  }

  /// Save notification time (format: "HH:mm")
  Future<bool> saveNotificationTime(String time) async {
    try {
      final result = await _preferences?.setString(_notificationTimeKey, time);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load notification time (format: "HH:mm")
  String loadNotificationTime() {
    try {
      final String? time = _preferences?.getString(_notificationTimeKey);
      return time ?? _defaultNotificationTime;
    } catch (e) {
      return _defaultNotificationTime;
    }
  }

  // ============================================================================
  // INDIVIDUAL NOTIFICATION TIME METHODS
  // ============================================================================

  /// Save devotional notification time
  Future<bool> saveDevotionalTime(String time) async {
    try {
      final result = await _preferences?.setString(_devotionalTimeKey, time);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load devotional notification time
  String loadDevotionalTime() {
    try {
      final String? time = _preferences?.getString(_devotionalTimeKey);
      return time ?? _defaultDevotionalTime;
    } catch (e) {
      return _defaultDevotionalTime;
    }
  }

  /// Save prayer notification time
  Future<bool> savePrayerTime(String time) async {
    try {
      final result = await _preferences?.setString(_prayerTimeKey, time);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load prayer notification time
  String loadPrayerTime() {
    try {
      final String? time = _preferences?.getString(_prayerTimeKey);
      return time ?? _defaultPrayerTime;
    } catch (e) {
      return _defaultPrayerTime;
    }
  }

  /// Save verse notification time
  Future<bool> saveVerseTime(String time) async {
    try {
      final result = await _preferences?.setString(_verseTimeKey, time);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load verse notification time
  String loadVerseTime() {
    try {
      final String? time = _preferences?.getString(_verseTimeKey);
      return time ?? _defaultVerseTime;
    } catch (e) {
      return _defaultVerseTime;
    }
  }

  /// Save reading plan notification time
  Future<bool> saveReadingPlanTime(String time) async {
    try {
      final result = await _preferences?.setString(_readingPlanTimeKey, time);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Load reading plan notification time
  String loadReadingPlanTime() {
    try {
      final String? time = _preferences?.getString(_readingPlanTimeKey);
      return time ?? _defaultReadingPlanTime;
    } catch (e) {
      return _defaultReadingPlanTime;
    }
  }

  // ============================================================================
  // READING PLAN REMINDERS METHODS
  // ============================================================================

  /// Enable/disable reading plan reminders
  Future<bool> saveReadingPlanReminders(bool enabled) async {
    try {
      final result = await _preferences?.setBool(_readingPlanRemindersKey, enabled);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if reading plan reminders are enabled
  bool loadReadingPlanReminders() {
    try {
      final bool? enabled = _preferences?.getBool(_readingPlanRemindersKey);
      return enabled ?? _defaultNotificationsEnabled;
    } catch (e) {
      return _defaultNotificationsEnabled;
    }
  }

  // ============================================================================
  // TERMS ACCEPTANCE METHODS
  // ============================================================================

  /// Save terms acceptance status
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveTermsAcceptance(bool accepted) async {
    try {
      final result = await _preferences?.setBool(_termsAcceptedKey, accepted);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has accepted terms
  ///
  /// Returns true if terms have been accepted, false otherwise.
  bool hasAcceptedTerms() {
    try {
      final bool? accepted = _preferences?.getBool(_termsAcceptedKey);
      return accepted ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // LEGAL AGREEMENTS ACCEPTANCE METHODS (Combined disclaimer + terms/privacy)
  // ============================================================================

  /// Save legal agreements acceptance status
  ///
  /// This covers the combined legal agreements screen that includes:
  /// - Crisis disclaimer
  /// - Terms of Service
  /// - Privacy Policy
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> saveLegalAgreementAcceptance(bool accepted) async {
    try {
      final result = await _preferences?.setBool(_legalAgreementsKey, accepted);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has accepted all legal agreements
  ///
  /// Returns true if legal agreements have been accepted, false otherwise.
  bool hasAcceptedLegalAgreements() {
    try {
      final bool? accepted = _preferences?.getBool(_legalAgreementsKey);
      return accepted ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // FAB TUTORIAL METHODS
  // ============================================================================

  /// Check if FAB menu tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasFabTutorialShown() {
    try {
      return _preferences?.getBool(_fabTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark FAB menu tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setFabTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_fabTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // VERSE LONG-PRESS TUTORIAL METHODS
  // ============================================================================

  /// Check if verse long-press tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasVerseTutorialShown() {
    try {
      return _preferences?.getBool(_verseTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark verse long-press tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setVerseTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_verseTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // PRAYER JOURNAL TUTORIAL METHODS
  // ============================================================================

  /// Check if prayer journal tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasPrayerTutorialShown() {
    try {
      return _preferences?.getBool(_prayerTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark prayer journal tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setPrayerTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_prayerTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // BIBLE BROWSER TUTORIAL METHODS
  // ============================================================================

  /// Check if Bible browser tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasBibleBrowserTutorialShown() {
    try {
      return _preferences?.getBool(_bibleBrowserTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark Bible browser tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setBibleBrowserTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_bibleBrowserTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // DEVOTIONAL VERSE TUTORIAL METHODS
  // ============================================================================

  /// Check if devotional verse tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasDevotionalVerseTutorialShown() {
    try {
      return _preferences?.getBool(_devotionalVerseTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark devotional verse tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setDevotionalVerseTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_devotionalVerseTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // CHAT TUTORIAL METHODS
  // ============================================================================

  /// Check if chat tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasChatTutorialShown() {
    try {
      return _preferences?.getBool(_chatTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark chat tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setChatTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_chatTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // READING PLAN TUTORIAL METHODS
  // ============================================================================

  /// Check if reading plan tutorial has been shown to user
  ///
  /// Returns true if tutorial has been shown, false otherwise.
  bool hasReadingPlanTutorialShown() {
    try {
      return _preferences?.getBool(_readingPlanTutorialShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark reading plan tutorial as shown
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setReadingPlanTutorialShown() async {
    try {
      final result = await _preferences?.setBool(_readingPlanTutorialShownKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // APP LOCK / BIOMETRIC AUTHENTICATION METHODS
  // ============================================================================

  /// Enable or disable app lock with biometric authentication
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setAppLockEnabled(bool enabled) async {
    try {
      final result = await _preferences?.setBool(_appLockEnabledKey, enabled);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if app lock is enabled
  ///
  /// Returns true if app lock is enabled, false otherwise.
  bool isAppLockEnabled() {
    try {
      return _preferences?.getBool(_appLockEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark biometric setup as completed (user has gone through onboarding prompt)
  ///
  /// Returns true if save was successful, false otherwise.
  Future<bool> setBiometricSetupCompleted() async {
    try {
      final result = await _preferences?.setBool(_biometricSetupCompletedKey, true);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric setup has been completed
  ///
  /// Returns true if user has seen/completed biometric setup, false otherwise.
  bool hasBiometricSetupCompleted() {
    try {
      return _preferences?.getBool(_biometricSetupCompletedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear all preferences (useful for testing or reset functionality)
  Future<bool> clearAll() async {
    try {
      final result = await _preferences?.clear();
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Clear specific preference by key
  Future<bool> remove(String key) async {
    try {
      final result = await _preferences?.remove(key);
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if preferences have been initialized
  bool get isInitialized => _preferences != null;

  /// Get all stored preferences (for debugging)
  Map<String, dynamic> getAllPreferences() {
    if (_preferences == null) {
      return {};
    }

    return {
      'theme_mode': _preferences!.getString(_themeModeKey),
      'language': _preferences!.getString(_languageKey),
      'text_size': _preferences!.getDouble(_textSizeKey),
    };
  }

  /// Reset singleton instance for testing
  ///
  /// WARNING: This method should ONLY be used in tests to reset the singleton
  /// state between test runs. Do not call this in production code.
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
    _preferences = null;
  }
}
