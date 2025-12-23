import 'package:flutter/material.dart';

/// Centralized gradient definitions for consistent glassmorphic design
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     gradient: AppGradients.glassMedium,
///     borderRadius: BorderRadius.circular(12),
///   ),
/// )
/// ```
class AppGradients {
  AppGradients._(); // Private constructor to prevent instantiation

  // ============================================================================
  // GLASS GRADIENTS (for glassmorphic UI elements)
  // ============================================================================

  /// Very subtle glass effect (0.10 → 0.05 alpha)
  /// Use for: Backgrounds, subtle overlays
  static const LinearGradient glassSubtle = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // White with 0.10 alpha (10%)
      Color(0x0DFFFFFF), // White with 0.05 alpha (5%)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Medium glass effect (0.15 → 0.08 alpha)
  /// Use for: Cards, containers, most UI elements
  static const LinearGradient glassMedium = LinearGradient(
    colors: [
      Color(0x26FFFFFF), // White with 0.15 alpha (15%)
      Color(0x14FFFFFF), // White with 0.08 alpha (8%)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Strong glass effect (0.20 → 0.10 alpha)
  /// Use for: Interactive elements, filter chips, active states
  static const LinearGradient glassStrong = LinearGradient(
    colors: [
      Color(0x33FFFFFF), // White with 0.20 alpha (20%)
      Color(0x1AFFFFFF), // White with 0.10 alpha (10%)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Very strong glass effect (0.25 → 0.15 alpha)
  /// Use for: Emphasized containers, highlighted elements
  static const LinearGradient glassVeryStrong = LinearGradient(
    colors: [
      Color(0x40FFFFFF), // White with 0.25 alpha (25%)
      Color(0x26FFFFFF), // White with 0.15 alpha (15%)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // THEME GRADIENTS (using app colors)
  // ============================================================================

  /// Primary theme gradient (indigo → purple)
  /// Use for: Primary buttons, key actions, progress indicators
  static const LinearGradient primary = LinearGradient(
    colors: [
      Color(0xFF6366F1), // AppTheme.primaryColor (indigo)
      Color(0xFF8B5CF6), // AppTheme.accentColor (purple)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold accent gradient (subtle gold overlay)
  /// Use for: User-related elements, profile sections, achievements
  static const LinearGradient goldAccent = LinearGradient(
    colors: [
      Color(0x4DD4AF37), // AppTheme.goldColor with 0.30 alpha
      Color(0x1AD4AF37), // AppTheme.goldColor with 0.10 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold accent for borders (stronger)
  /// Use for: Borders, outlines, highlights
  static const LinearGradient goldBorder = LinearGradient(
    colors: [
      Color(0x99D4AF37), // AppTheme.goldColor with 0.60 alpha
      Color(0x66D4AF37), // AppTheme.goldColor with 0.40 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // BACKGROUND GRADIENTS
  // ============================================================================

  /// Dark background gradient (navy → deep blue → dark purple)
  /// Use for: Main app background (GradientBackground widget)
  static const LinearGradient backgroundDark = LinearGradient(
    colors: [
      Color(0xFF1A1A2E), // Dark navy
      Color(0xFF16213E), // Deep blue
      Color(0xFF0F3460), // Dark purple
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Light background gradient (off-white → light blue)
  /// Use for: Light mode background (if implemented)
  static const LinearGradient backgroundLight = LinearGradient(
    colors: [
      Color(0xFFF8FAFF), // Off-white
      Color(0xFFE8F2FF), // Light blue
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // BUTTON GRADIENTS
  // ============================================================================

  /// Button gradient (glass medium for enabled state)
  /// Use for: Default button backgrounds
  static const LinearGradient button = glassMedium;

  /// Button gradient disabled state (very subtle)
  /// Use for: Disabled buttons
  static const LinearGradient buttonDisabled = LinearGradient(
    colors: [
      Color(0x1A808080), // Gray with 0.10 alpha
      Color(0x0D808080), // Gray with 0.05 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // STATUS GRADIENTS (for different states)
  // ============================================================================

  /// Success gradient (green overlay)
  /// Use for: Success messages, completed states
  static const LinearGradient success = LinearGradient(
    colors: [
      Color(0x4D4CAF50), // Green with 0.30 alpha
      Color(0x1A4CAF50), // Green with 0.10 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warning gradient (orange overlay)
  /// Use for: Warning messages, caution states
  static const LinearGradient warning = LinearGradient(
    colors: [
      Color(0x4DFFA726), // Orange with 0.30 alpha
      Color(0x1AFFA726), // Orange with 0.10 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Error gradient (red overlay)
  /// Use for: Error messages, delete actions
  static const LinearGradient error = LinearGradient(
    colors: [
      Color(0x4DF44336), // Red with 0.30 alpha
      Color(0x1AF44336), // Red with 0.10 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Info gradient (blue overlay)
  /// Use for: Info messages, help states
  static const LinearGradient info = LinearGradient(
    colors: [
      Color(0x4D2196F3), // Blue with 0.30 alpha
      Color(0x1A2196F3), // Blue with 0.10 alpha
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Create a custom glass gradient with specified alpha values
  ///
  /// Example:
  /// ```dart
  /// final customGlass = AppGradients.customGlass(0.18, 0.09);
  /// ```
  static LinearGradient customGlass(double startAlpha, double endAlpha) {
    return LinearGradient(
      colors: [
        Color.fromRGBO(255, 255, 255, startAlpha),
        Color.fromRGBO(255, 255, 255, endAlpha),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Create a custom colored gradient with specified color and alpha values
  ///
  /// Example:
  /// ```dart
  /// final customColor = AppGradients.customColored(
  ///   Colors.purple,
  ///   startAlpha: 0.30,
  ///   endAlpha: 0.10,
  /// );
  /// ```
  static LinearGradient customColored(
    Color color, {
    double startAlpha = 0.30,
    double endAlpha = 0.10,
  }) {
    return LinearGradient(
      colors: [
        color.withValues(alpha: startAlpha),
        color.withValues(alpha: endAlpha),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
