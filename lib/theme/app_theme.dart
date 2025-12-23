import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white.withValues(alpha: 0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return toggleActiveColor.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
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
        shadowColor: primaryColor.withValues(alpha: 0.3),
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
    scaffoldBackgroundColor: const Color(0xFF121212),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return Colors.white.withValues(alpha: 0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return toggleActiveColor.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
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
        shadowColor: primaryColor.withValues(alpha: 0.3),
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
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
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
    backgroundColor: Colors.white.withValues(alpha: 0.1),
    foregroundColor: Colors.white,
    elevation: 0,
    side: BorderSide(
      color: Colors.white.withValues(alpha: 0.2),
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
    backgroundColor: primaryColor.withValues(alpha: 0.8),
    foregroundColor: Colors.white,
    elevation: 8,
    shadowColor: primaryColor.withValues(alpha: 0.4),
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

// ============================================================================
// DESIGN TOKEN SYSTEM - Semantic constants for consistent styling
// ============================================================================

/// Spacing constants for consistent padding, margin, and gaps
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base spacing scale (4px base unit)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // Common padding patterns
  static const EdgeInsets screenPadding = EdgeInsets.all(xl);
  static const EdgeInsets screenPaddingLarge = EdgeInsets.all(xxl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xxl, vertical: lg);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: xl, vertical: lg);

  // Horizontal spacing
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  // Vertical spacing
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: xxl);

  // Gaps between elements
  static const double gapXs = xs;
  static const double gapSm = sm;
  static const double gapMd = md;
  static const double gapLg = lg;
  static const double gapXl = xl;
  static const double gapXxl = xxl;
}

/// Semantic color tokens for consistent color usage
class AppColors {
  AppColors._();

  // Text colors on dark backgrounds (gradients)
  static const Color primaryText = Colors.white;
  static final Color secondaryText = Colors.white.withValues(alpha: 0.8);
  static final Color tertiaryText = Colors.white.withValues(alpha: 0.6);
  static final Color disabledText = Colors.white.withValues(alpha: 0.4);

  // Text colors on light backgrounds
  static const Color darkPrimaryText = Colors.black87;
  static final Color darkSecondaryText = Colors.black.withValues(alpha: 0.6);
  static final Color darkTertiaryText = Colors.black.withValues(alpha: 0.4);

  // Accent colors for emphasis
  static const Color accent = AppTheme.goldColor;
  static final Color accentSubtle = AppTheme.goldColor.withValues(alpha: 0.6);
  static final Color accentVerySubtle = AppTheme.goldColor.withValues(alpha: 0.3);

  // Background overlays
  static final Color glassOverlayLight = Colors.white.withValues(alpha: 0.15);
  static final Color glassOverlayMedium = Colors.white.withValues(alpha: 0.1);
  static final Color glassOverlaySubtle = Colors.white.withValues(alpha: 0.05);

  // Border colors
  static final Color primaryBorder = Colors.white.withValues(alpha: 0.2);
  static final Color accentBorder = AppTheme.goldColor.withValues(alpha: 0.6);
  static final Color subtleBorder = Colors.white.withValues(alpha: 0.1);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  AppRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double pill = 100.0; // For fully rounded elements

  // Common border radius patterns
  static final BorderRadius smallRadius = BorderRadius.circular(sm);
  static final BorderRadius mediumRadius = BorderRadius.circular(md);
  static final BorderRadius cardRadius = BorderRadius.circular(lg);
  static final BorderRadius largeCardRadius = BorderRadius.circular(xl);
  static final BorderRadius buttonRadius = BorderRadius.circular(xxl);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

/// Border styles for consistent component borders
class AppBorders {
  AppBorders._();

  // Primary glass borders (gold accent)
  static final Border primaryGlass = Border.all(
    color: AppColors.accentBorder,
    width: 2.0,
  );

  static final Border primaryGlassSubtle = Border.all(
    color: AppTheme.goldColor.withValues(alpha: 0.5),
    width: 1.5,
  );

  static final Border primaryGlassThin = Border.all(
    color: AppTheme.goldColor.withValues(alpha: 0.3),
    width: 1.0,
  );

  // Subtle white borders
  static final Border subtle = Border.all(
    color: AppColors.primaryBorder,
    width: 1.0,
  );

  static final Border subtleThick = Border.all(
    color: AppColors.primaryBorder,
    width: 2.0,
  );

  // Icon container borders
  static final Border iconContainer = Border.all(
    color: AppColors.accentBorder,
    width: 1.5,
  );

  // No border
  static const Border none = Border();
}

/// Animation duration and timing constants
class AppAnimations {
  AppAnimations._();

  // Standard durations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Sequential animation delays
  static const Duration sequentialShort = Duration(milliseconds: 100);
  static const Duration sequentialMedium = Duration(milliseconds: 150);
  static const Duration sequentialLong = Duration(milliseconds: 200);

  // Common animation durations by type
  static const Duration fadeIn = slow;
  static const Duration slideIn = normal;
  static const Duration scaleIn = normal;
  static const Duration shimmer = Duration(milliseconds: 1500);

  // Base delays for screen entry animations
  static const Duration baseDelay = slow;
  static const Duration sectionDelay = Duration(milliseconds: 400);
}

/// Component size constants
class AppSizes {
  AppSizes._();

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Avatar/circle sizes
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;

  // Card sizes
  static const double statCardWidth = 140.0;
  static const double statCardHeight = 120.0;
  static const double quickActionWidth = 100.0;
  static const double quickActionHeight = 120.0;

  // App bar
  static const double appBarHeight = 56.0;
  static const double appBarIconSize = iconMd;

  // Button heights
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
}

/// Glass effect blur strength constants
class AppBlur {
  AppBlur._();

  static const double light = 15.0;
  static const double medium = 25.0;
  static const double strong = 40.0;
  static const double veryStrong = 60.0;
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
    double r = color.r;
    double g = color.g;
    double b = color.b;

    // Apply sRGB gamma correction
    r = (r <= 0.03928) ? r / 12.92 : _pow((r + 0.055) / 1.055, 2.4);
    g = (g <= 0.03928) ? g / 12.92 : _pow((g + 0.055) / 1.055, 2.4);
    b = (b <= 0.03928) ? b / 12.92 : _pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Power function helper (dart:math pow returns num, we need double)
  static double _pow(double base, double exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent * 10; i++) {
      result *= base;
      if (i % 10 == 9) result = result; // Every 10 iterations = 1.0 power
    }
    // Approximate for fractional exponents
    if (exponent == 2.4) {
      // base^2.4 ≈ base^2 * base^0.4
      result = base * base * _sqrtApprox(base); // Rough approximation
    }
    return result;
  }

  /// Simple square root approximation
  static double _sqrtApprox(double n) {
    if (n < 0) return 0;
    double x = n;
    double y = 1.0;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = n / x;
    }
    return x;
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