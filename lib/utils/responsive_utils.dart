import 'package:flutter/material.dart';

/// Responsive design utilities for adaptive layouts across all device sizes
class ResponsiveUtils {
  /// Device breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    if (width < desktopBreakpoint) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop or larger
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get responsive font size based on screen width AND user's text scale preference
  /// Base size scales proportionally with screen width, multiplied by user's text scale,
  /// then clamped to min/max constraints
  static double fontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale factor: 375 is baseline (iPhone SE/8), desktop gets larger
    final screenScaleFactor = screenWidth / 375;

    // Apply user's text scale preference (from textSizeProvider via MediaQuery)
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Apply both scaling factors to base size
    final scaled = baseSize * screenScaleFactor * textScaleFactor;

    // Apply constraints to the final scaled result
    double finalSize = scaled;
    if (minSize != null && finalSize < minSize) finalSize = minSize;
    if (maxSize != null && finalSize > maxSize) finalSize = maxSize;

    return finalSize;
  }

  /// Get responsive spacing based on screen size
  static double spacing(BuildContext context, double baseSpacing) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseSpacing;
      case DeviceType.tablet:
        return baseSpacing * 1.2;
      case DeviceType.desktop:
        return baseSpacing * 1.5;
      case DeviceType.largeDesktop:
        return baseSpacing * 1.8;
    }
  }

  /// Get responsive value based on device type
  static T valueByDevice<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
  }) {
    final deviceType = getDeviceType(context);
    final multiplier = deviceType == DeviceType.mobile
        ? 1.0
        : deviceType == DeviceType.tablet
            ? 1.5
            : 2.0;

    return EdgeInsets.symmetric(
      horizontal: horizontal * multiplier,
      vertical: vertical * multiplier,
    );
  }

  /// Get screen width percentage
  static double widthPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.width * (percent / 100);
  }

  /// Get screen height percentage
  static double heightPercent(BuildContext context, double percent) {
    return MediaQuery.of(context).size.height * (percent / 100);
  }

  /// Get responsive grid columns
  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop;
    }
  }

  /// Calculate responsive item size for grids
  /// Returns item width based on available space, column count, and spacing
  static double gridItemWidth(
    BuildContext context, {
    required int columns,
    double spacing = 8.0,
    double horizontalPadding = 16.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalHorizontalPadding = horizontalPadding * 2;
    final totalSpacing = spacing * (columns - 1);
    final availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
    return availableWidth / columns;
  }

  /// Get orientation-aware value
  static T valueByOrientation<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait ? portrait : landscape;
  }

  /// Scale size responsively with constraints
  static double scaleSize(
    BuildContext context,
    double size, {
    double minScale = 0.8,
    double maxScale = 1.5,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = (screenWidth / 375).clamp(minScale, maxScale);
    return size * scale;
  }

  /// Get max content width for large screens (prevents overstretching)
  static double maxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 800;
      case DeviceType.desktop:
        return 1000;
      case DeviceType.largeDesktop:
        return 1200;
    }
  }

  /// Get responsive border radius
  static double borderRadius(BuildContext context, double baseRadius) {
    return scaleSize(context, baseRadius, minScale: 0.8, maxScale: 1.5);
  }

  /// Get responsive icon size
  static double iconSize(BuildContext context, double baseSize) {
    return scaleSize(context, baseSize, minScale: 0.8, maxScale: 1.5);
  }
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Extension on BuildContext for convenient access to responsive utilities
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils();

  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  double fontSize(double size, {double? min, double? max}) =>
      ResponsiveUtils.fontSize(this, size, minSize: min, maxSize: max);

  double spacing(double base) => ResponsiveUtils.spacing(this, base);

  double widthPercent(double percent) =>
      ResponsiveUtils.widthPercent(this, percent);

  double heightPercent(double percent) =>
      ResponsiveUtils.heightPercent(this, percent);
}
