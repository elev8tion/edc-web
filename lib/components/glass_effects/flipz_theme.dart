import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Theme configuration for the Flipz app
///
/// Color Usage Guidelines:
/// - successColor: Use for all success states, verified badges, default selections, checkmarks
/// - errorColor: Use for errors, destructive actions, danger states
/// - warningColor: Use for pending states, cautions, in-progress indicators
/// - accent1: Use for informational badges, tags (shipping, billing, etc.)
/// - primaryColor: Use for primary brand elements, main CTAs
/// - vibrantColor: Reserved for special emphasis (avoid for standard success states)
class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF00A8C7); // Primary
  static const Color secondaryColor = Color(0xFFF13786); // Secondary
  static const Color tertiaryColor = Color(0xFFEE8B60); // Tertiary
  static const Color alternateColor = Color(0xFF787DC0); // Alternate

  // Utility Colors
  static const Color primaryText = Color(0xFFFFFFFF); // Primary Text
  static const Color secondaryText = Color(0xFFCBD3E1); // Secondary Text
  static const Color primaryBackground =
      Color(0xFF000000); // Primary Background
  static const Color secondaryBackground =
      Color(0xFF14181B); // Secondary Background

  // Accent Colors
  static const Color accent1 = Color(0xFF3A86FF); // Accent 1 - Used for informational badges, tags, secondary highlights
  static const Color accent2 = Color(0xFFFFCE00); // Accent 2 - Used for attention-grabbing elements
  static const Color accent3 =
      Color(0xFF6C3A6F); // Accent 3 - Used for special features
  static const Color accent4 = Color(0xFF8338EC); // Accent 4 - Used for premium features

  // Semantic Colors
  static const Color successColor = Color.fromARGB(233, 6, 204, 121); // Success - Used for verified states, default selections, success indicators
  static const Color errorColor = Color(0xFFFF5963); // Error - Used for destructive actions, errors, danger states
  static const Color warningColor = Color(0xFFF9CF58); // Warning - Used for caution states, pending actions
  static const Color infoColor = Color(0xFFFFFFFF); // Info - Used for informational messages

  // Custom Colors
  static const Color vibrantColor = Color(0xFF2CAA4A); // vibrantColor
  static const Color mutedColor = Color(0xFF77AF4D); // mutedColor
  static const Color frost1 = Color(0xFF42315C); // frost1 - corrected to valid hex
  static const Color frost2 = Color(0xFF36252D); // frost2 - corrected to valid hex
  static const Color frostShadow =
      Color(0x30FFFFFF); // frostShadow - back to original
  static const Color frostShadow2 =
      Color(0x2CFFFFFF); // frostShadow2 - corrected
  static const Color blackText = Color(0xFF000000); // Black Text
  static const Color whiteText = Color(0xFFFFFFFF); // White text

  static const Color backgroundColor = Color(0x1A000000); // Background
  static const Color border = Color(0x66FFFFFF); // Border
  static const Color greenLightColor = Color(0xFF2E7D32); // Updated to match visual weight of yellow/red
  static const Color yellowLightColor = Color(0xFFFFCE00); // yellowLightColor
  static const Color redLightColor = Color(0xFF990721); // redLightColor

  // Money/Currency and Confidence colors - darker green for better visibility
  static const Color greenConfidenceColor = Color(0xFF2E7D32); // Dark green for money/currency displays and high confidence
  static const Color moneyColor = greenConfidenceColor; // Alias for all money displays (prices, dollar amounts, etc.)

  // Typography
  static String get primaryFontFamily => 'Plus Jakarta Sans';
  static String get secondaryFontFamily => 'Space Grotesk';

  // Main theme (dark only)
  static ThemeData get theme => darkTheme;

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: primaryBackground,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: tertiaryColor,
          surface: secondaryBackground,
          error: errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: primaryText,
          onError: Colors.white,
          outline: border,
        ),
        textTheme: _buildTextTheme(primaryText, secondaryText),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBackground,
          foregroundColor: primaryText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.smallRadius,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.smallRadius,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: secondaryBackground,
          labelStyle: const TextStyle(color: Colors.white),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
            borderSide: const BorderSide(color: secondaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mediumRadius,
          ),
          color: secondaryBackground,
        ),
      );

  // Dropdown Styling Standard
  // All dropdowns should use this consistent styling to match dialog appearance
  static BoxDecoration dropdownDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withValues(alpha: 0.85),
        Colors.black.withValues(alpha: 0.75),
      ],
      stops: const [0.0, 1.0],
      begin: const AlignmentDirectional(0.98, -1.0),
      end: const AlignmentDirectional(-0.98, 1.0),
    ),
    borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
    border: Border.all(
      color: border,
      width: 2,
    ),
  );

  // Standard dropdown button decoration (container wrapper)
  static BoxDecoration dropdownButtonDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withValues(alpha: 0.15),
        Colors.black.withValues(alpha: 0.10),
      ],
      stops: const [0.0, 1.0],
      begin: const AlignmentDirectional(0.98, -1.0),
      end: const AlignmentDirectional(-0.98, 1.0),
    ),
    borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
    border: Border.all(
      color: border,
      width: 2,
    ),
  );

  // Standard dropdown menu properties
  static const BorderRadius dropdownMenuBorderRadius = BorderRadius.all(Radius.circular(AppRadius.md));
  static const EdgeInsets dropdownPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // Blur dropdown text styles
  static TextStyle dropdownActiveTextStyle = GoogleFonts.spaceGrotesk(
    color: blackText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle dropdownInactiveTextStyle = GoogleFonts.spaceGrotesk(
    color: primaryText,
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static TextStyle dropdownPlaceholderTextStyle = GoogleFonts.spaceGrotesk(
    color: primaryText.withValues(alpha: 0.6),
    fontSize: 14,
  );

  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 64,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 44,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      // Headline styles
      headlineLarge: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      // Title styles
      titleLarge: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // Label styles
      labelLarge: GoogleFonts.spaceGrotesk(
        color: secondaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        color: secondaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        color: secondaryText,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
      // Body styles
      bodyLarge: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.spaceGrotesk(
        color: primaryText,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}