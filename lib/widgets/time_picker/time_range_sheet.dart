import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'time_range_sheet_style.dart';
import 'models/time_range_data.dart';
import '../../components/base_bottom_sheet.dart';

/// A highly customizable time range picker bottom sheet widget
///
/// This widget provides a beautiful and intuitive interface for selecting
/// time ranges with extensive customization options including colors,
/// typography, animations, and validation.
class TimeRangeSheet extends StatefulWidget {
  /// Initial start time for the picker
  final TimeOfDay? initialStartTime;

  /// Initial end time for the picker
  final TimeOfDay? initialEndTime;

  /// Callback fired when user confirms the time selection
  final Function(TimeOfDay startTime, TimeOfDay endTime)? onConfirm;

  /// Callback fired when user cancels the selection
  final VoidCallback? onCancel;

  /// Comprehensive style configuration for the widget
  final TimeRangeSheetStyle? style;

  /// Whether to allow invalid time ranges (start time after end time)
  final bool allowInvalidRange;

  /// Custom validation function for business logic
  /// Returns true if the time range is valid
  final bool Function(TimeOfDay start, TimeOfDay end)? customValidator;

  /// Whether the widget accepts user interaction
  final bool enabled;

  /// Whether to show start time tab initially (true) or end time tab (false)
  final bool showStartTimeInitially;

  /// If true, only a single time picker is shown (no start/end distinction)
  final bool singlePicker;

  const TimeRangeSheet({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
    this.onConfirm,
    this.onCancel,
    this.style,
    this.allowInvalidRange = false,
    this.customValidator,
    this.enabled = true,
    this.showStartTimeInitially = true,
    this.singlePicker = false,
  });

  @override
  State<TimeRangeSheet> createState() => _TimeRangeSheetState();
}

class _TimeRangeSheetState extends State<TimeRangeSheet> with TickerProviderStateMixin {
  // Time state management
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TimeRangeSheetStyle _style;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Tab state (0 = start time, 1 = end time)
  int _selectedTabIndex = 0;

  // Scroll controllers for smooth time picker animations
  FixedExtentScrollController? _hourController;
  FixedExtentScrollController? _minuteController;

  // State to track if controllers are animating
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _setupAnimations();

    // Initialize scroll controllers after the first frame to ensure proper positioning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateToCurrentTime();
    });
  }

  /// Initialize the widget state with default or provided values
  void _initializeState() {
    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.initialEndTime ?? const TimeOfDay(hour: 17, minute: 0);
    _style = widget.style ?? TimeRangeSheetStyle.light();
    _selectedTabIndex = widget.showStartTimeInitially ? 0 : 1;
  }

  /// Setup fade-in animation for the widget
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: _style.animationDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: _style.animationCurve ?? Curves.easeInOut,
      ),
    );

    // Start the fade-in animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hourController?.dispose();
    _minuteController?.dispose();
    super.dispose();
  }

  bool get _isValidRange {
    if (widget.allowInvalidRange) return true;
    if (widget.customValidator != null) {
      return widget.customValidator!(_startTime, _endTime);
    }
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return startMinutes < endMinutes;
  }

  bool get _shouldShowError {
    return !_isValidRange && !_isAnimating;
  }

  String get _errorMessage {
    return _style.errorMessage ?? 'Start time must be before end time';
  }

  void _updateStartTime(TimeOfDay newTime) {
    if (!widget.enabled) return;
    setState(() {
      _startTime = newTime;
    });
    if (_style.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _updateEndTime(TimeOfDay newTime) {
    if (!widget.enabled) return;
    setState(() {
      _endTime = newTime;
    });
    if (_style.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _onConfirm() {
    if (!_isValidRange && !widget.allowInvalidRange) return;
    if (_style.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onConfirm?.call(_startTime, _endTime);
  }

  void _onCancel() {
    if (_style.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onCancel?.call();
  }

  FixedExtentScrollController _getOrCreateHourController(int initialItem) {
    // Only create new controller if null - avoid disposing active controllers
    _hourController ??= FixedExtentScrollController(initialItem: initialItem);
    return _hourController!;
  }

  FixedExtentScrollController _getOrCreateMinuteController(int initialItem) {
    // Only create new controller if null - avoid disposing active controllers
    _minuteController ??= FixedExtentScrollController(initialItem: initialItem);
    return _minuteController!;
  }

  void _animateToCurrentTime() {
    // Safety check: don't animate if not mounted
    if (!mounted) return;

    // Get the current time for the selected tab
    final time = _selectedTabIndex == 0 ? _startTime : _endTime;
    final hour = _style.use24HourFormat ? time.hour : (time.hour % 12 == 0 ? 12 : time.hour % 12);
    final minute = time.minute;

    // Calculate the correct indices for the pickers
    final hourIndex = hour - (_style.use24HourFormat ? 0 : 1);
    final minuteIndex = minute;

    // Animate to the correct positions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Safety check: don't animate if disposed
      if (!mounted) return;

      if (_hourController != null && _hourController!.hasClients) {
        _hourController!
            .animateToItem(
          hourIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
      }
      if (_minuteController != null && _minuteController!.hasClients) {
        _minuteController!.animateToItem(
          minuteIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use dark style if in dark mode and no custom style provided
    if (widget.style == null && isDarkMode) {
      _style = TimeRangeSheetStyle.dark();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message outside the sheet
          if (_shouldShowError) _buildErrorMessage(context, theme),
          // Main sheet container - transparent to allow GlassBottomSheet blur
          SizedBox(
            height: _style.sheetHeight ?? (isTablet ? 500 : 450),
            child: Column(
              children: [
                _buildHeader(context, theme),
                Expanded(child: _buildTimePickers(context, theme, isTablet)),
                _buildActionButtons(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    if (!widget.singlePicker) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_style.cornerRadius ?? 20),
          ),
        ),
        child: Column(
          children: [
            // Tab buttons
            Container(
              padding: _style.headerPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      context,
                      theme,
                      _style.startTimeLabel ?? 'Start time',
                      _formatTime(_startTime),
                      0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTabButton(
                      context,
                      theme,
                      _style.endTimeLabel ?? 'End time',
                      _formatTime(_endTime),
                      1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink(); // Hide header when single picker is true
    }
  }

  /// Builds a tab button for start/end time selection
  Widget _buildTabButton(BuildContext context, ThemeData theme, String label, String time, int tabIndex) {
    final isSelected = _selectedTabIndex == tabIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = tabIndex;
          _isAnimating = true;
        });
        // Animate to the correct time when switching tabs
        _animateToCurrentTime();
        if (_style.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? (_style.sheetBackgroundColor ?? theme.scaffoldBackgroundColor) : Colors.transparent,
          borderRadius: BorderRadius.circular(_style.buttonCornerRadius ?? 12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (_style.shadowColor ?? Colors.black).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: _style.labelTextStyle ??
                  TextStyle(
                    color: isSelected
                        ? (_style.labelTextColor ?? theme.textTheme.bodyMedium?.color)
                        : (_style.labelTextColor ?? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: _style.fontFamily,
                  ),
            ),
            SizedBox(height: _style.labelSpacing ?? 6),
            Text(
              time,
              style: _style.selectedTimeTextStyle ??
                  TextStyle(
                    color: isSelected
                        ? (_style.selectedTimeTextColor ?? theme.textTheme.headlineSmall?.color)
                        : (_style.selectedTimeTextColor ?? theme.textTheme.headlineSmall?.color?.withValues(alpha: 0.5)),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: _style.fontFamily,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the error message widget with modern styling
  Widget _buildErrorMessage(BuildContext context, ThemeData theme) {
    return AnimatedContainer(
      duration: _style.animationDuration ?? const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: _style.errorPadding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_style.errorTextColor ?? Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_style.cornerRadius ?? 12),
      ),
      child: Row(
        children: [
          // Warning icon with circular background
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _style.errorTextColor ?? Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Error message text
          Expanded(
            child: Text(
              _errorMessage,
              style: _style.errorTextStyle ??
                  TextStyle(
                    color: _style.errorTextColor ?? Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: _style.fontFamily,
                  ),
            ),
          ),
          // Close indicator
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (_style.errorTextColor ?? Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.close,
              color: (_style.errorTextColor ?? Colors.red).withValues(alpha: 0.7),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickers(BuildContext context, ThemeData theme, bool isTablet) {
    return Padding(
      padding: _style.padding ?? const EdgeInsets.all(16),
      child: widget.singlePicker
          ? _buildTimePicker(context, theme, true, isTablet)
          : _buildTimePicker(context, theme, _selectedTabIndex == 0, isTablet),
    );
  }

  Widget _buildTimePicker(BuildContext context, ThemeData theme, bool isStart, bool isTablet) {
    final time = isStart ? _startTime : _endTime;
    final hour = _style.use24HourFormat ? time.hour : (time.hour % 12 == 0 ? 12 : time.hour % 12);
    final minute = time.minute;
    final isPM = time.hour >= 12;

    if (!widget.singlePicker) {
      return Row(
        children: [
          // Hour picker
          Expanded(
            flex: 2,
            child: _buildScrollPicker(
              context,
              theme,
              _style.use24HourFormat ? 24 : 12,
              hour - (_style.use24HourFormat ? 0 : 1),
              (index) {
                int newHour;
                if (_style.use24HourFormat) {
                  newHour = index;
                } else {
                  // For 12-hour format, keep the AM/PM state and only change the hour within that period
                  final hourIn12Format = index + 1;
                  if (isPM) {
                    // PM: hours 1-12 become 13-24 (but 12 PM stays as 12)
                    newHour = hourIn12Format == 12 ? 12 : hourIn12Format + 12;
                  } else {
                    // AM: hours 1-12 become 1-12 (but 12 AM becomes 0)
                    newHour = hourIn12Format == 12 ? 0 : hourIn12Format;
                  }
                }
                final newTime = TimeOfDay(hour: newHour, minute: minute);
                if (isStart) {
                  _updateStartTime(newTime);
                } else {
                  _updateEndTime(newTime);
                }
              },
              (index) => _style.use24HourFormat ? index.toString().padLeft(2, '0') : (index + 1).toString().padLeft(2, '0'),
              _getOrCreateHourController(hour - (_style.use24HourFormat ? 0 : 1)),
              _style.hourLabel,
            ),
          ),
          const SizedBox(width: 8),
          // Minute picker
          Expanded(
            flex: 2,
            child: _buildScrollPicker(
              context,
              theme,
              60,
              minute,
              (index) {
                final newTime = TimeOfDay(hour: time.hour, minute: index);
                if (isStart) {
                  _updateStartTime(newTime);
                } else {
                  _updateEndTime(newTime);
                }
              },
              (index) => index.toString().padLeft(2, '0'),
              _getOrCreateMinuteController(minute),
              _style.minuteLabel,
            ),
          ),
          if (!_style.use24HourFormat) ...[
            const SizedBox(width: 8),
            // AM/PM picker
            Expanded(
              flex: 1,
              child: _buildAmPmToggle(context, theme, isPM, (isNewPM) {
                // Don't do anything if clicking the already-selected option
                if (isNewPM == isPM) return;

                // Convert hour based on new AM/PM selection
                int newHour;
                final currentHour12 = time.hour % 12; // Get hour in 12-hour format (0-11)

                if (isNewPM) {
                  // Converting to PM: add 12 to the 12-hour format
                  // Special case: if hour is 0 (12 AM), it becomes 12 (12 PM)
                  newHour = currentHour12 == 0 ? 12 : currentHour12 + 12;
                } else {
                  // Converting to AM: use 12-hour format directly
                  // Special case handled: 12 PM (hour 12) becomes 12 AM (hour 0)
                  newHour = currentHour12;
                }

                final newTime = TimeOfDay(hour: newHour, minute: minute);
                if (isStart) {
                  _updateStartTime(newTime);
                } else {
                  _updateEndTime(newTime);
                }
              }),
            ),
          ],
        ],
      );
    } else {
      // This is the single picker mode
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              children: [
                // Hour picker (single mode)
                Expanded(
                  flex: 2,
                  child: _buildScrollPicker(
                    context,
                    theme,
                    _style.use24HourFormat ? 24 : 12,
                    hour - (_style.use24HourFormat ? 0 : 1),
                    (index) {
                      int newHour;
                      if (_style.use24HourFormat) {
                        newHour = index;
                      } else {
                        final hourIn12Format = index + 1;
                        newHour = isPM ? (hourIn12Format == 12 ? 12 : hourIn12Format + 12) : (hourIn12Format == 12 ? 0 : hourIn12Format);
                      }
                      final newTime = TimeOfDay(hour: newHour, minute: minute);
                      _updateStartTime(newTime);
                    },
                    (index) => _style.use24HourFormat ? index.toString().padLeft(2, '0') : (index + 1).toString().padLeft(2, '0'),
                    _getOrCreateHourController(hour - (_style.use24HourFormat ? 0 : 1)),
                    _style.hourLabel,
                  ),
                ),
                const SizedBox(width: 8),
                // Minute picker (single mode)
                Expanded(
                  flex: 2,
                  child: _buildScrollPicker(
                    context,
                    theme,
                    60,
                    minute,
                    (index) {
                      final newTime = TimeOfDay(hour: time.hour, minute: index);
                      _updateStartTime(newTime);
                    },
                    (index) => index.toString().padLeft(2, '0'),
                    _getOrCreateMinuteController(minute),
                    _style.minuteLabel,
                  ),
                ),
                if (!_style.use24HourFormat) ...[
                  const SizedBox(width: 8),
                  // AM/PM picker (single mode)
                  Expanded(
                    flex: 1,
                    child: _buildAmPmToggle(context, theme, isPM, (isNewPM) {
                      // Don't do anything if clicking the already-selected option
                      if (isNewPM == isPM) return;

                      // Convert hour based on new AM/PM selection
                      int newHour;
                      final currentHour12 = time.hour % 12; // Get hour in 12-hour format (0-11)

                      if (isNewPM) {
                        // Converting to PM: add 12 to the 12-hour format
                        // Special case: if hour is 0 (12 AM), it becomes 12 (12 PM)
                        newHour = currentHour12 == 0 ? 12 : currentHour12 + 12;
                      } else {
                        // Converting to AM: use 12-hour format directly
                        // Special case handled: 12 PM (hour 12) becomes 12 AM (hour 0)
                        newHour = currentHour12;
                      }

                      final newTime = TimeOfDay(hour: newHour, minute: minute);
                      _updateStartTime(newTime);
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }

  /// Builds a scrollable picker for hours/minutes with enhanced styling
  Widget _buildScrollPicker(
    BuildContext context,
    ThemeData theme,
    int itemCount,
    int selectedIndex,
    Function(int) onChanged,
    String Function(int) itemBuilder,
    FixedExtentScrollController? controller,
    String? label,
  ) {
    return Column(
      children: [
        if (label != null) ...[
          Text(
            label,
            style: _style.selectedTimeTextStyle ??
                TextStyle(
                  color: _style.labelTextColor ?? theme.textTheme.bodyMedium?.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: _style.fontFamily,
                ),
          ),
          SizedBox(height: _style.labelSpacing ?? 8),
        ],
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller ?? FixedExtentScrollController(initialItem: selectedIndex),
            itemExtent: _style.pickerItemHeight ?? 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= itemCount) return null;
                final isSelected = index == selectedIndex;

                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    itemBuilder(index),
                    style: _style.pickerTextStyle?.copyWith(
                          color: isSelected
                              ? (_style.selectedPickerTextColor ?? theme.textTheme.headlineSmall?.color)
                              : (_style.pickerTextColor ?? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: isSelected ? 32 : 24,
                          fontFamily: _style.fontFamily,
                        ) ??
                        TextStyle(
                          color: isSelected
                              ? (_style.selectedPickerTextColor ?? theme.textTheme.headlineSmall?.color)
                              : (_style.pickerTextColor ?? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                          fontSize: isSelected ? 32 : 24,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: _style.fontFamily,
                        ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmPmToggle(
    BuildContext context,
    ThemeData theme,
    bool isPM,
    Function(bool) onChanged,
  ) {
    return Column(
      children: [
        Expanded(
          child: _buildAmPmButton(
            context,
            theme,
            _style.amText ?? 'AM',
            !isPM,
            () => onChanged(false),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildAmPmButton(
            context,
            theme,
            _style.pmText ?? 'PM',
            isPM,
            () => onChanged(true),
          ),
        ),
      ],
    );
  }

  /// Builds an AM/PM toggle button with dark gradient styling
  Widget _buildAmPmButton(
    BuildContext context,
    ThemeData theme,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final borderColor = isSelected
        ? const Color(0xFF9C7FFF) // AppTheme.primaryColor for selected
        : Colors.white.withValues(alpha: 0.2); // Subtle border for unselected

    return GestureDetector(
      onTap: () {
        onTap();
        if (_style.enableHapticFeedback) {
          HapticFeedback.selectionClick();
        }
      },
      child: Container(
        height: (_style.pickerItemHeight ?? 50) * 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
            begin: const AlignmentDirectional(0.98, -1.0),
            end: const AlignmentDirectional(-0.98, 1.0),
          ),
          borderRadius: BorderRadius.circular(_style.buttonCornerRadius ?? 12),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: _style.fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Padding(
      padding: _style.buttonPadding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGlassButton(
            context: context,
            theme: theme,
            text: _style.confirmButtonText ?? 'Use these times',
            onPressed: _isValidRange ? _onConfirm : null,
            isPrimary: true,
          ),
          SizedBox(height: _style.buttonSpacing ?? 12),
          _buildGlassButton(
            context: context,
            theme: theme,
            text: _style.cancelButtonText ?? 'Cancel',
            onPressed: _onCancel,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  /// Builds an action button with dark gradient styling
  Widget _buildGlassButton({
    required BuildContext context,
    required ThemeData theme,
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    final borderColor = isPrimary
        ? const Color(0xFF9C7FFF) // AppTheme.primaryColor
        : Colors.white.withValues(alpha: 0.2);

    final textColor = onPressed != null
        ? (_style.buttonTextColor ?? Colors.white)
        : Colors.white.withValues(alpha: 0.3);

    return SizedBox(
      width: double.infinity,
      height: _style.buttonHeight ?? 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPrimary
                ? [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.15),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
            begin: const AlignmentDirectional(0.98, -1.0),
            end: const AlignmentDirectional(-0.98, 1.0),
          ),
          borderRadius: BorderRadius.circular(_style.buttonCornerRadius ?? 28),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_style.buttonCornerRadius ?? 28),
            child: Center(
              child: Text(
                text,
                style: _style.buttonTextStyle ??
                    TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: _style.fontFamily,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    if (_style.use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final period = time.hour >= 12 ? (_style.pmText ?? 'PM') : (_style.amText ?? 'AM');
      return '${hour.toString()}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }
}

/// Helper function to show the TimeRangeSheet in a modal bottom sheet with dark gradient styling
///
/// This is the recommended way to display the time range picker as a modal.
/// Uses the app's standard dark gradient bottom sheet for consistent UI.
///
/// Returns a [TimeRangeData] object if the user confirms their selection,
/// or null if they cancel or dismiss the sheet.
Future<TimeRangeData?> showTimeRangeSheet({
  required BuildContext context,
  TimeOfDay? initialStartTime,
  TimeOfDay? initialEndTime,
  TimeRangeSheetStyle? style,
  bool allowInvalidRange = false,
  bool Function(TimeOfDay start, TimeOfDay end)? customValidator,
  bool enabled = true,
  bool isScrollControlled = true,
  bool enableDrag = true,
  bool isDismissible = true,
  bool showStartTimeInitially = true,
  bool singlePicker = false,
}) {
  // Auto-detect theme and apply appropriate style
  final effectiveStyle =
      style ?? (Theme.of(context).brightness == Brightness.dark ? TimeRangeSheetStyle.dark() : TimeRangeSheetStyle.light());

  return showCustomBottomSheet<TimeRangeData>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    isDismissible: isDismissible && effectiveStyle.dismissOnTapOutside,
    showHandle: true,
    child: TimeRangeSheet(
      initialStartTime: initialStartTime,
      initialEndTime: initialEndTime,
      style: effectiveStyle,
      allowInvalidRange: allowInvalidRange,
      customValidator: customValidator,
      enabled: enabled,
      onConfirm: (start, end) {
        Navigator.of(context).pop(TimeRangeData(
          startTime: start,
          endTime: end,
        ));
      },
      showStartTimeInitially: showStartTimeInitially,
      onCancel: () => Navigator.of(context).pop(),
      singlePicker: singlePicker,
    ),
  );
}
