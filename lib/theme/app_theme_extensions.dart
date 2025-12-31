import 'package:flutter/material.dart';
import 'package:everyday_christian/theme/app_theme.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.appSpacing,
    required this.appColors,
    required this.appRadius,
    required this.appBorders,
    required this.appAnimations,
    required this.appSizes,
    required this.appBlur,
  });

  final AppSpacing appSpacing;
  final AppColors appColors;
  final AppRadius appRadius;
  final AppBorders appBorders;
  final AppAnimations appAnimations;
  final AppSizes appSizes;
  final AppBlur appBlur;

  @override
  ThemeExtension<AppThemeExtension> copyWith({
    AppSpacing? appSpacing,
    AppColors? appColors,
    AppRadius? appRadius,
    AppBorders? appBorders,
    AppAnimations? appAnimations,
    AppSizes? appSizes,
    AppBlur? appBlur,
  }) {
    return AppThemeExtension(
      appSpacing: appSpacing ?? this.appSpacing,
      appColors: appColors ?? this.appColors,
      appRadius: appRadius ?? this.appRadius,
      appBorders: appBorders ?? this.appBorders,
      appAnimations: appAnimations ?? this.appAnimations,
      appSizes: appSizes ?? this.appSizes,
      appBlur: appBlur ?? this.appBlur,
    );
  }

  @override
  ThemeExtension<AppThemeExtension> lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return this; // Lerping is not necessary for these tokens as they don't change between themes
  }
}

// ============================================================================
// DESIGN TOKEN SYSTEM - Semantic constants for consistent styling
// ============================================================================

/// Spacing constants for consistent padding, margin, and gaps
class AppSpacing {
  const AppSpacing();

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
  const AppColors();

  // Text colors on dark backgrounds (gradients)
  static const Color primaryText = Colors.white;
  static final Color secondaryText = Colors.white.withOpacity(0.8);
  static final Color tertiaryText = Colors.white.withOpacity(0.6);
  static final Color disabledText = Colors.white.withOpacity(0.4);

  // Text colors on light backgrounds
  static const Color darkPrimaryText = Colors.black87;
  static final Color darkSecondaryText = Colors.black.withOpacity(0.6);
  static final Color darkTertiaryText = Colors.black.withOpacity(0.4);

  // Accent colors for emphasis
  static const Color accent = AppTheme.goldColor;
  static final Color accentSubtle = AppTheme.goldColor.withOpacity(0.6);
  static final Color accentVerySubtle = AppTheme.goldColor.withOpacity(0.3);

  // Background overlays
  static final Color glassOverlayLight = Colors.white.withOpacity(0.15);
  static final Color glassOverlayMedium = Colors.white.withOpacity(0.1);
  static final Color glassOverlaySubtle = Colors.white.withOpacity(0.05);

  // Border colors
  static final Color primaryBorder = Colors.white.withOpacity(0.2);
  static final Color accentBorder = AppTheme.goldColor.withOpacity(0.6);
  static final Color subtleBorder = Colors.white.withOpacity(0.1);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  const AppRadius();

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
  const AppBorders();

  // Primary glass borders (gold accent)
  static final Border primaryGlass = Border.all(
    color: AppColors.accentBorder,
    width: 2.0,
  );

  static final Border primaryGlassSubtle = Border.all(
    color: AppTheme.goldColor.withOpacity(0.5),
    width: 1.5,
  );

  static final Border primaryGlassThin = Border.all(
    color: AppTheme.goldColor.withOpacity(0.3),
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
  const AppAnimations();

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

  // Home screen staggered animation delays
  static const Duration homeStatsCardDelay = Duration(milliseconds: 600);
  static const Duration homeMainFeatureDelay1 = Duration(milliseconds: 1000);
  static const Duration homeMainFeatureDelay2 = Duration(milliseconds: 1100);
  static const Duration homeQuickActionsHeaderDelay = Duration(milliseconds: 1200);
  static const Duration homeQuickActionsRowDelay = Duration(milliseconds: 1300);
  static const Duration homeDailyVerseDelay = Duration(milliseconds: 1400);
  static const Duration homeStartChatDelay = Duration(milliseconds: 1500);
}

/// Component size constants
class AppSizes {
  const AppSizes();

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
  const AppBlur();

  static const double light = 15.0;
  static const double medium = 25.0;
  static const double strong = 40.0;
  static const double veryStrong = 60.0;
}
