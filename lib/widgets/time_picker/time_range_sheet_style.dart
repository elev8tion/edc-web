import 'package:flutter/material.dart';

/// Comprehensive style configuration for TimeRangeSheet widget
///
/// This class provides extensive customization options for every aspect
/// of the time range picker, including colors, typography, layout,
/// animations, and accessibility features.
class TimeRangeSheetStyle {
  // ==================== Color Customization ====================

  /// Background color for the header section
  final Color? headerBackgroundColor;

  /// Background color for the main sheet area
  final Color? sheetBackgroundColor;

  /// Color for label text (Start time, End time)
  final Color? labelTextColor;

  /// Color for selected time display text
  final Color? selectedTimeTextColor;

  /// Color for unselected picker items
  final Color? pickerTextColor;

  /// Color for selected picker items
  final Color? selectedPickerTextColor;

  /// Color for divider lines
  final Color? dividerColor;

  /// Background color for the confirm button
  final Color? buttonColor;

  /// Background color for the cancel button
  final Color? cancelButtonColor;

  /// Text color for the confirm button
  final Color? buttonTextColor;

  /// Text color for the cancel button
  final Color? cancelButtonTextColor;

  /// Color for error messages and validation
  final Color? errorTextColor;

  /// Color for shadows and elevation effects
  final Color? shadowColor;

  /// Background color for AM/PM toggle buttons
  final Color? amPmToggleColor;

  /// Color for selected AM/PM state
  final Color? amPmSelectedColor;

  // ==================== Typography Customization ====================

  /// Custom text style for labels
  final TextStyle? labelTextStyle;

  /// Custom text style for selected time display
  final TextStyle? selectedTimeTextStyle;

  /// Custom text style for picker items
  final TextStyle? pickerTextStyle;

  /// Custom text style for buttons
  final TextStyle? buttonTextStyle;

  /// Custom text style for error messages
  final TextStyle? errorTextStyle;

  /// Font family to use throughout the widget
  final String? fontFamily;

  // ==================== Size & Layout Customization ====================

  /// Total height of the sheet
  final double? sheetHeight;

  /// Height of the header section
  final double? headerHeight;

  /// Width of each picker column
  final double? pickerColumnWidth;

  /// Height of individual picker items
  final double? pickerItemHeight;

  /// Height of action buttons
  final double? buttonHeight;

  /// Size of AM/PM toggle buttons
  final double? amPmToggleSize;

  /// General padding around content
  final EdgeInsets? padding;

  /// Padding for the header section
  final EdgeInsets? headerPadding;

  /// Padding around picker columns
  final EdgeInsets? pickerPadding;

  /// Padding around action buttons
  final EdgeInsets? buttonPadding;

  /// Padding around error messages
  final EdgeInsets? errorPadding;

  /// Spacing between major sections
  final double? sectionSpacing;

  /// Spacing between labels and content
  final double? labelSpacing;

  /// Spacing between buttons
  final double? buttonSpacing;

  // ==================== Shape & Border Customization ====================

  /// Corner radius for the main sheet
  final double? cornerRadius;

  /// Corner radius for buttons
  final double? buttonCornerRadius;

  /// Corner radius for AM/PM toggle
  final double? amPmToggleCornerRadius;

  /// Custom border styling
  final BorderSide? borderSide;

  /// Custom shadow effect
  final BoxShadow? shadow;

  // ==================== Animation & Interaction ====================

  /// Duration for animations
  final Duration? animationDuration;

  /// Animation curve for transitions
  final Curve? animationCurve;

  /// Whether to provide haptic feedback
  final bool enableHapticFeedback;

  /// Whether tapping outside dismisses the sheet
  final bool dismissOnTapOutside;

  // ==================== Accessibility & Internationalization ====================

  /// Whether to use 24-hour time format
  final bool use24HourFormat;

  /// Custom text for AM indicator
  final String? amText;

  /// Custom text for PM indicator
  final String? pmText;

  /// Custom label for start time section
  final String? startTimeLabel;

  /// Custom label for end time section
  final String? endTimeLabel;

  /// Custom label for the hour picker
  final String? hourLabel;

  /// Custom label for the minute picker
  final String? minuteLabel;

  /// Custom text for confirm button
  final String? confirmButtonText;

  /// Custom text for cancel button
  final String? cancelButtonText;

  /// Custom error message text
  final String? errorMessage;

  /// Whether to enable semantic labels for accessibility
  final bool enableSemanticLabels;

  /// Creates a new TimeRangeSheetStyle with the specified customizations
  ///
  /// All parameters are optional and will fall back to sensible defaults
  /// or theme-based values when not specified.
  const TimeRangeSheetStyle({
    // Color customization
    this.headerBackgroundColor,
    this.sheetBackgroundColor,
    this.labelTextColor,
    this.selectedTimeTextColor,
    this.pickerTextColor,
    this.selectedPickerTextColor,
    this.dividerColor,
    this.buttonColor,
    this.cancelButtonColor,
    this.buttonTextColor,
    this.cancelButtonTextColor,
    this.errorTextColor,
    this.shadowColor,
    this.amPmToggleColor,
    this.amPmSelectedColor,

    // Typography customization
    this.labelTextStyle,
    this.selectedTimeTextStyle,
    this.pickerTextStyle,
    this.buttonTextStyle,
    this.errorTextStyle,
    this.fontFamily,

    // Size & layout customization
    this.sheetHeight,
    this.headerHeight,
    this.pickerColumnWidth,
    this.pickerItemHeight,
    this.buttonHeight,
    this.amPmToggleSize,
    this.padding,
    this.headerPadding,
    this.pickerPadding,
    this.buttonPadding,
    this.errorPadding,
    this.sectionSpacing,
    this.labelSpacing,
    this.buttonSpacing,

    // Shape & border customization
    this.cornerRadius,
    this.buttonCornerRadius,
    this.amPmToggleCornerRadius,
    this.borderSide,
    this.shadow,

    // Animation & interaction
    this.animationDuration,
    this.animationCurve,
    this.enableHapticFeedback = true,
    this.dismissOnTapOutside = true,

    // Accessibility & internationalization
    this.use24HourFormat = false,
    this.amText,
    this.pmText,
    this.startTimeLabel,
    this.endTimeLabel,
    this.hourLabel,
    this.minuteLabel,
    this.confirmButtonText,
    this.cancelButtonText,
    this.errorMessage,
    this.enableSemanticLabels = true,
  });

  /// Creates a copy of this style with the given fields replaced
  TimeRangeSheetStyle copyWith({
    // Color customization
    Color? headerBackgroundColor,
    Color? sheetBackgroundColor,
    Color? labelTextColor,
    Color? selectedTimeTextColor,
    Color? pickerTextColor,
    Color? selectedPickerTextColor,
    Color? dividerColor,
    Color? buttonColor,
    Color? cancelButtonColor,
    Color? buttonTextColor,
    Color? cancelButtonTextColor,
    Color? errorTextColor,
    Color? shadowColor,
    Color? amPmToggleColor,
    Color? amPmSelectedColor,

    // Typography customization
    TextStyle? labelTextStyle,
    TextStyle? selectedTimeTextStyle,
    TextStyle? pickerTextStyle,
    TextStyle? buttonTextStyle,
    TextStyle? errorTextStyle,
    String? fontFamily,

    // Size & layout customization
    double? sheetHeight,
    double? headerHeight,
    double? pickerColumnWidth,
    double? pickerItemHeight,
    double? buttonHeight,
    double? amPmToggleSize,
    EdgeInsets? padding,
    EdgeInsets? headerPadding,
    EdgeInsets? pickerPadding,
    EdgeInsets? buttonPadding,
    EdgeInsets? errorPadding,
    double? sectionSpacing,
    double? labelSpacing,
    double? buttonSpacing,

    // Shape & border customization
    double? cornerRadius,
    double? buttonCornerRadius,
    double? amPmToggleCornerRadius,
    BorderSide? borderSide,
    BoxShadow? shadow,

    // Animation & interaction
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableHapticFeedback,
    bool? dismissOnTapOutside,

    // Accessibility & internationalization
    bool? use24HourFormat,
    String? amText,
    String? pmText,
    String? startTimeLabel,
    String? endTimeLabel,
    String? hourLabel,
    String? minuteLabel,
    String? confirmButtonText,
    String? cancelButtonText,
    String? errorMessage,
    bool? enableSemanticLabels,
  }) {
    return TimeRangeSheetStyle(
      // Color customization
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      sheetBackgroundColor: sheetBackgroundColor ?? this.sheetBackgroundColor,
      labelTextColor: labelTextColor ?? this.labelTextColor,
      selectedTimeTextColor: selectedTimeTextColor ?? this.selectedTimeTextColor,
      pickerTextColor: pickerTextColor ?? this.pickerTextColor,
      selectedPickerTextColor: selectedPickerTextColor ?? this.selectedPickerTextColor,
      dividerColor: dividerColor ?? this.dividerColor,
      buttonColor: buttonColor ?? this.buttonColor,
      cancelButtonColor: cancelButtonColor ?? this.cancelButtonColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      cancelButtonTextColor: cancelButtonTextColor ?? this.cancelButtonTextColor,
      errorTextColor: errorTextColor ?? this.errorTextColor,
      shadowColor: shadowColor ?? this.shadowColor,
      amPmToggleColor: amPmToggleColor ?? this.amPmToggleColor,
      amPmSelectedColor: amPmSelectedColor ?? this.amPmSelectedColor,

      // Typography customization
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      selectedTimeTextStyle: selectedTimeTextStyle ?? this.selectedTimeTextStyle,
      pickerTextStyle: pickerTextStyle ?? this.pickerTextStyle,
      buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      errorTextStyle: errorTextStyle ?? this.errorTextStyle,
      fontFamily: fontFamily ?? this.fontFamily,

      // Size & layout customization
      sheetHeight: sheetHeight ?? this.sheetHeight,
      headerHeight: headerHeight ?? this.headerHeight,
      pickerColumnWidth: pickerColumnWidth ?? this.pickerColumnWidth,
      pickerItemHeight: pickerItemHeight ?? this.pickerItemHeight,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      amPmToggleSize: amPmToggleSize ?? this.amPmToggleSize,
      padding: padding ?? this.padding,
      headerPadding: headerPadding ?? this.headerPadding,
      pickerPadding: pickerPadding ?? this.pickerPadding,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      errorPadding: errorPadding ?? this.errorPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,

      // Shape & border customization
      cornerRadius: cornerRadius ?? this.cornerRadius,
      buttonCornerRadius: buttonCornerRadius ?? this.buttonCornerRadius,
      amPmToggleCornerRadius: amPmToggleCornerRadius ?? this.amPmToggleCornerRadius,
      borderSide: borderSide ?? this.borderSide,
      shadow: shadow ?? this.shadow,

      // Animation & interaction
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      dismissOnTapOutside: dismissOnTapOutside ?? this.dismissOnTapOutside,

      // Accessibility & internationalization
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      amText: amText ?? this.amText,
      pmText: pmText ?? this.pmText,
      startTimeLabel: startTimeLabel ?? this.startTimeLabel,
      endTimeLabel: endTimeLabel ?? this.endTimeLabel,
      hourLabel: hourLabel ?? this.hourLabel,
      minuteLabel: minuteLabel ?? this.minuteLabel,
      confirmButtonText: confirmButtonText ?? this.confirmButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
      errorMessage: errorMessage ?? this.errorMessage,
      enableSemanticLabels: enableSemanticLabels ?? this.enableSemanticLabels,
    );
  }

  /// Default style for light theme
  static TimeRangeSheetStyle light() {
    return const TimeRangeSheetStyle(
      headerBackgroundColor: Color(0xFFF5F5F5),
      sheetBackgroundColor: Colors.white,
      labelTextColor: Color(0xFF666666),
      selectedTimeTextColor: Colors.black,
      pickerTextColor: Color(0xFF999999),
      selectedPickerTextColor: Colors.black,
      dividerColor: Color(0xFFE0E0E0),
      buttonColor: Colors.blue,
      cancelButtonColor: Color(0xFF999999),
      buttonTextColor: Colors.white,
      cancelButtonTextColor: Colors.white,
      errorTextColor: Colors.red,
      shadowColor: Colors.black26,
      amPmToggleColor: Color(0xFFF0F0F0),
      amPmSelectedColor: Colors.blue,
      cornerRadius: 20.0,
      buttonCornerRadius: 12.0,
      amPmToggleCornerRadius: 8.0,
      pickerItemHeight: 50.0,
      buttonHeight: 50.0,
      padding: EdgeInsets.all(16.0),
      headerPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      pickerPadding: EdgeInsets.symmetric(horizontal: 8.0),
      buttonPadding: EdgeInsets.symmetric(horizontal: 16.0),
      errorPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sectionSpacing: 24.0,
      labelSpacing: 8.0,
      buttonSpacing: 12.0,
      animationDuration: Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
    );
  }

  /// Default style for dark theme
  static TimeRangeSheetStyle dark() {
    return const TimeRangeSheetStyle(
      headerBackgroundColor: Color(0xFF2A2A2A),
      sheetBackgroundColor: Color(0xFF1E1E1E),
      labelTextColor: Color(0xFFB0B0B0),
      selectedTimeTextColor: Colors.white,
      pickerTextColor: Color(0xFF666666),
      selectedPickerTextColor: Colors.white,
      dividerColor: Color(0xFF404040),
      buttonColor: Colors.blue,
      cancelButtonColor: Color(0xFF666666),
      buttonTextColor: Colors.white,
      cancelButtonTextColor: Colors.white,
      errorTextColor: Color(0xFFFF6B6B),
      shadowColor: Colors.black54,
      amPmToggleColor: Color(0xFF404040),
      amPmSelectedColor: Colors.blue,
      cornerRadius: 20.0,
      buttonCornerRadius: 12.0,
      amPmToggleCornerRadius: 8.0,
      pickerItemHeight: 50.0,
      buttonHeight: 50.0,
      padding: EdgeInsets.all(16.0),
      headerPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      pickerPadding: EdgeInsets.symmetric(horizontal: 8.0),
      buttonPadding: EdgeInsets.symmetric(horizontal: 16.0),
      errorPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sectionSpacing: 24.0,
      labelSpacing: 8.0,
      buttonSpacing: 12.0,
      animationDuration: Duration(milliseconds: 300),
      animationCurve: Curves.easeInOut,
    );
  }
}
