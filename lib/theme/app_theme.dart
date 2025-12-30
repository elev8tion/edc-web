import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:everyday_christian/theme/app_theme_extensions.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1); // Modern indigo
  static const Color accentColor = Color(0xFF8B5CF6); // Beautiful purple
  static const Color secondaryColor = Color(0xFF64748B); // Slate gray
  static const Color goldColor = Color(0xFFD4AF37); // Gold/amber from logo
  static const Color toggleActiveColor = Color(0xFFFFA726); // Amber/orange

  // Experimental Accent Colors - Color Palette 01
  static const Color experimentalNavy = Color(0xFF494A8A); // Deep navy blue
  static const Color experimentalPurple = Color(0xFF925892); // Medium purple
  static const Color experimentalRose = Color(0xFFC05E91); // Rose/mauve
  static const Color experimentalPeach = Color(0xFFFFC39D); // Light peach
  static const Color experimentalCoral = Color(0xFFFE9397); // Soft coral
  static const Color experimentalPink = Color(0xFFF86888); // Vibrant pink

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    extensions: const <ThemeExtension<dynamic>>[
      AppThemeExtension(
        appSpacing: AppSpacing(),
        appColors: AppColors(),
        appRadius: AppRadius(),
        appBorders: AppBorders(),
        appAnimations: AppAnimations(),
        appSizes: AppSizes(),
        appBlur: AppBlur(),
      ),
    ],
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white.withOpacity(0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return toggleActiveColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
      trackOutlineColor: WidgetStateProperty.all(toggleActiveColor),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: primaryColor,
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.largeCardRadius,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: AppRadius.largeCardRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.largeCardRadius,
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppThemeExtension(
        appSpacing: AppSpacing(),
        appColors: AppColors(),
        appRadius: AppRadius(),
        appBorders: AppBorders(),
        appAnimations: AppAnimations(),
        appSizes: AppSizes(),
        appBlur: AppBlur(),
      ),
    ],
    scaffoldBackgroundColor: const Color(0xFF121212),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white.withOpacity(0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return toggleActiveColor.withOpacity(0.5);
        }
        return Colors.grey.withOpacity(0.3);
      }),
      trackOutlineColor: WidgetStateProperty.all(toggleActiveColor),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: primaryColor,
      titleTextStyle: TextStyle(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.largeCardRadius,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800,
      border: OutlineInputBorder(
        borderRadius: AppRadius.largeCardRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.largeCardRadius,
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(color: Colors.grey.shade400),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  );

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFE8F2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
  );

  // Beautiful Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Standardized text shadows for consistent styling
  static const List<Shadow> textShadowSubtle = [
    Shadow(
      color: Color(0x26000000), // 15% opacity
      offset: Offset(0, 1),
      blurRadius: 2.0,
    ),
  ];

  static const List<Shadow> textShadowMedium = [
    Shadow(
      color: Color(0x4D000000), // 30% opacity
      offset: Offset(0, 1),
      blurRadius: 3.0,
    ),
  ];

  static const List<Shadow> textShadowStrong = [
    Shadow(
      color: Color(0x66000000), // 40% opacity
      offset: Offset(0, 2),
      blurRadius: 4.0,
    ),
  ];

  static const List<Shadow> textShadowBold = [
    Shadow(
      color: Color(0x80000000), // 50% opacity
      offset: Offset(0, 2),
      blurRadius: 6.0,
    ),
  ];

  // Text styles optimized for glass components
  static const TextStyle headingStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: textShadowMedium,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    shadows: textShadowSubtle,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Colors.white,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFFB0B0B0),
  );

  // Icon themes for glass visibility
  static const IconThemeData glassIconTheme = IconThemeData(
    color: Colors.white,
    size: 24,
  );

  static const IconThemeData accentIconTheme = IconThemeData(
    color: primaryColor,
    size: 24,
  );

  // Glass button styles
  static ButtonStyle glassButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.1),
    foregroundColor: Colors.white,
    elevation: 0,
    side: BorderSide(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.buttonRadius,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle primaryGlassButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor.withOpacity(0.8),
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: primaryColor.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.buttonRadius,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}



/// WCAG Contrast Ratio Calculator for Accessibility
///
/// Verifies color contrast meets WCAG 2.1 Level AA standards:
/// - Normal text: 4.5:1 minimum
/// - Large text (≥18pt): 3:1 minimum
/// - UI components: 3:1 minimum
class WCAGContrast {
  WCAGContrast._();

  /// Calculate relative luminance using WCAG formula
  static double _relativeLuminance(Color color) {
    double r = color.red / 255.0;
    double g = color.green / 255.0;
    double b = color.blue / 255.0;

    // Apply sRGB gamma correction
    r = (r <= 0.03928) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
    g = (g <= 0.03928) ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
    b = (b <= 0.03928) ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate contrast ratio between two colors
  static double contrastRatio(Color foreground, Color background) {
    double lum1 = _relativeLuminance(foreground) + 0.05;
    double lum2 = _relativeLuminance(background) + 0.05;

    double ratio = lum1 > lum2 ? lum1 / lum2 : lum2 / lum1;
    return ratio;
  }

  /// Check if contrast meets WCAG AA standard (4.5:1 for normal text)
  static bool meetsWcagAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast meets WCAG AA standard for large text (3:1)
  static bool meetsWcagAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  /// Check if contrast meets WCAG AAA standard (7:1 for normal text)
  static bool meetsWcagAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Get formatted contrast ratio string
  static String getContrastReport(Color foreground, Color background) {
    double ratio = contrastRatio(foreground, background);
    bool passAA = ratio >= 4.5;
    bool passAAA = ratio >= 7.0;

    return '${ratio.toStringAsFixed(2)}:1 ${passAA ? "✅ WCAG AA" : "❌ FAIL AA"}${passAAA ? " ✅ AAA" : ""}';
  }

  /// Verify app theme colors meet WCAG standards
  static void verifyThemeContrast() {
    debugPrint('\n═══ WCAG Contrast Verification Report ═══\n');

    // Test user message bubble (white text on primaryGradient)
    debugPrint('USER MESSAGE BUBBLE:');
    debugPrint('  White on Indigo (#6366F1): ${getContrastReport(Colors.white, AppTheme.primaryColor)}');
    debugPrint('  White on Purple (#8B5CF6): ${getContrastReport(Colors.white, AppTheme.accentColor)}');

    // Test gold accent
    debugPrint('\nGOLD ACCENT:');
    debugPrint('  Gold (#D4AF37) on Dark: ${getContrastReport(AppTheme.goldColor, const Color(0xFF1E293B))}');
    debugPrint('  White on Gold: ${getContrastReport(Colors.white, AppTheme.goldColor)}');

    // Test AI message bubble (assumed white text on card color)
    debugPrint('\nAI MESSAGE BUBBLE:');
    debugPrint('  Dark text on Light card: ${getContrastReport(Colors.black87, Colors.white)}');

    debugPrint('\n═══════════════════════════════════════════\n');
  }
}