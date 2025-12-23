import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Floating badge that appears briefly after sending a message
/// Shows remaining messages with auto-dismiss animation
class FloatingMessageBadge extends StatefulWidget {
  final int remainingMessages;
  final bool isPremium;
  final bool isInTrial;

  const FloatingMessageBadge({
    super.key,
    required this.remainingMessages,
    required this.isPremium,
    required this.isInTrial,
  });

  // Track current overlay entry to prevent duplicates
  static OverlayEntry? _currentEntry;

  /// Show the floating badge with auto-dismiss
  /// Prevents duplicate entries by removing existing one first
  static void show({
    required BuildContext context,
    required int remainingMessages,
    required bool isPremium,
    required bool isInTrial,
  }) {
    // Remove existing entry to prevent stacking
    _removeCurrentEntry();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _FloatingMessageBadgeOverlay(
        remainingMessages: remainingMessages,
        isPremium: isPremium,
        isInTrial: isInTrial,
        onDismiss: () {
          _removeEntry(entry);
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Safely remove an overlay entry
  static void _removeEntry(OverlayEntry entry) {
    try {
      entry.remove();
      if (_currentEntry == entry) {
        _currentEntry = null;
      }
    } catch (_) {
      // Entry already removed, ignore
    }
  }

  /// Remove current entry if it exists
  static void _removeCurrentEntry() {
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {
        // Already removed, ignore
      }
      _currentEntry = null;
    }
  }

  @override
  State<FloatingMessageBadge> createState() => _FloatingMessageBadgeState();
}

class _FloatingMessageBadgeState extends State<FloatingMessageBadge> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.goldColor.withValues(alpha: 0.95),
            AppTheme.goldColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: ResponsiveUtils.iconSize(context, 16),
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.remainingMessages} ${_getMessageLabel()}',
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: AppTheme.textShadowSubtle,
            ),
          ),
        ],
      ),
    );
  }

  String _getMessageLabel() {
    if (widget.isPremium) {
      return widget.remainingMessages == 1 ? 'message left this month' : 'messages left this month';
    } else if (widget.isInTrial) {
      return widget.remainingMessages == 1 ? 'message left' : 'messages left';
    } else {
      return widget.remainingMessages == 1 ? 'message left' : 'messages left';
    }
  }
}

/// Internal overlay widget that handles positioning and auto-dismiss
class _FloatingMessageBadgeOverlay extends StatefulWidget {
  final int remainingMessages;
  final bool isPremium;
  final bool isInTrial;
  final VoidCallback onDismiss;

  const _FloatingMessageBadgeOverlay({
    required this.remainingMessages,
    required this.isPremium,
    required this.isInTrial,
    required this.onDismiss,
  });

  @override
  State<_FloatingMessageBadgeOverlay> createState() => _FloatingMessageBadgeOverlayState();
}

class _FloatingMessageBadgeOverlayState extends State<_FloatingMessageBadgeOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Position above the input area (bottom: 100px accounts for input height + safe area)
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: FloatingMessageBadge(
            remainingMessages: widget.remainingMessages,
            isPremium: widget.isPremium,
            isInTrial: widget.isInTrial,
          )
              .animate()
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
              .then(delay: 1700.ms) // Wait before fade out
              .fadeOut(duration: 300.ms, curve: Curves.easeIn),
        ),
      ),
    );
  }
}
