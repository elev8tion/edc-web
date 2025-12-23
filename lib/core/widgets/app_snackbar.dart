import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// Shared glass-style snackbar used for success/info feedback.
class AppSnackBar {
  AppSnackBar._();

  static const List<Color> _defaultGradient = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle,
    Color? iconColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: icon,
      iconColor: iconColor ?? AppTheme.goldColor,
      borderColor: AppTheme.goldColor.withValues(alpha: 0.3),
      gradientColors: _defaultGradient,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_outline,
      iconColor: Colors.red.shade300,
      borderColor: Colors.red.withValues(alpha: 0.5),
      gradientColors: _defaultGradient,
      duration: duration,
    );
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required List<Color> gradientColors,
    required Duration duration,
  }) {
    // Announce message to screen readers
    SemanticsService.announce(message, TextDirection.ltr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        content: _SnackBarContent(
          message: message,
          icon: icon,
          iconColor: iconColor,
          borderColor: borderColor,
          gradientColors: gradientColors,
        ),
      ),
    );
  }
}

class _SnackBarContent extends StatelessWidget {
  const _SnackBarContent({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.gradientColors,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final Color borderColor;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: ResponsiveUtils.iconSize(context, 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
