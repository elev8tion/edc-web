import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

/// Displays formatted time and message status indicator
/// Adapted to glassmorphic design system
class TimeAndStatus extends StatelessWidget {
  final DateTime timestamp;
  final MessageStatus? status;
  final bool showTime;
  final bool showStatus;
  final TextStyle? textStyle;
  final Color? statusColor;

  const TimeAndStatus({
    super.key,
    required this.timestamp,
    this.status,
    this.showTime = true,
    this.showStatus = true,
    this.textStyle,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 11,
      color: Colors.white.withValues(alpha: 0.6),
      fontWeight: FontWeight.w500,
      shadows: AppTheme.textShadowSubtle,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTime)
          Text(
            _formatTime(timestamp),
            style: textStyle ?? defaultStyle,
          ),
        if (showTime && showStatus && status != null) const SizedBox(width: 4),
        if (showStatus && status != null) _buildStatusIndicator(),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;

    switch (status!) {
      case MessageStatus.sending:
        return SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              statusColor ?? Colors.white.withValues(alpha: 0.6),
            ),
          ),
        );
      case MessageStatus.sent:
        icon = Icons.check;
        color = statusColor ?? Colors.white.withValues(alpha: 0.6);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = statusColor ?? AppTheme.primaryColor;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = statusColor ?? Colors.red.withValues(alpha: 0.8);
        break;
    }

    return Icon(
      icon,
      size: 12,
      color: color,
      shadows: AppTheme.textShadowSubtle,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    // If today, show time
    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(dateTime);
    }
    // If yesterday
    else if (diff.inDays == 1) {
      return 'Yesterday';
    }
    // If within a week
    else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(dateTime); // Day name
    }
    // Otherwise show date
    else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

/// Extension to easily add TimeAndStatus to messages
extension TimeAndStatusX on ChatMessage {
  Widget buildTimeAndStatus({
    bool showTime = true,
    bool showStatus = true,
    TextStyle? textStyle,
    Color? statusColor,
  }) {
    return TimeAndStatus(
      timestamp: timestamp,
      status: status,
      showTime: showTime,
      showStatus: showStatus,
      textStyle: textStyle,
      statusColor: statusColor,
    );
  }
}
