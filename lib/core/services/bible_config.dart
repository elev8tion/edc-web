import 'package:flutter/material.dart';

/// Centralized configuration for Bible translations and language mappings
///
/// This provides a single source of truth for:
/// - Language code → Bible version mapping
/// - Version metadata (full names, abbreviations)
/// - Language detection utilities
class BibleConfig {
  /// Map language codes to Bible translation versions
  ///
  /// - 'en' → WEB (World English Bible)
  /// - 'es' → RVR1909 (Reina-Valera 1909)
  static String getVersion(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'RVR1909';
      case 'en':
      default:
        return 'WEB';
    }
  }

  /// Extract language code from Locale
  ///
  /// Returns: 'en' or 'es'
  static String getLanguage(Locale locale) {
    return locale.languageCode;
  }

  /// Get both version and language from Locale
  ///
  /// Returns: {'version': 'WEB', 'language': 'en'}
  static Map<String, String> getConfig(Locale locale) {
    final language = getLanguage(locale);
    return {
      'version': getVersion(language),
      'language': language,
    };
  }

  /// Full names of Bible versions
  static const Map<String, String> versionNames = {
    'WEB': 'World English Bible',
    'RVR1909': 'Reina-Valera 1909',
  };

  /// Abbreviated names for UI display
  static const Map<String, String> versionAbbreviations = {
    'WEB': 'WEB',
    'RVR1909': 'RVR1909',
  };

  /// Get user-friendly version name
  static String getVersionName(String version) {
    return versionNames[version] ?? version;
  }

  /// Get version abbreviation
  static String getVersionAbbreviation(String version) {
    return versionAbbreviations[version] ?? version;
  }

  /// Check if a version is available
  static bool isVersionAvailable(String version) {
    return versionNames.containsKey(version);
  }

  /// Get list of all available versions
  static List<String> get availableVersions => versionNames.keys.toList();

  /// Get list of all supported languages
  static List<String> get supportedLanguages => ['en', 'es'];
}
