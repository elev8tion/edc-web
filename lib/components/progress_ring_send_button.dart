import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';

/// Progress ring that wraps the send button to show remaining messages
/// Displays as a circular progress indicator with message count
class ProgressRingSendButton extends StatelessWidget {
  final bool canSend;
  final VoidCallback? onPressed;
  final int remainingMessages;
  final int totalMessages;
  final bool isPremium;

  const ProgressRingSendButton({
    super.key,
    required this.canSend,
    required this.onPressed,
    required this.remainingMessages,
    required this.totalMessages,
    required this.isPremium,
  });

  Color _getProgressColor() {
    final progress = remainingMessages / totalMessages;
    if (progress > 0.6) {
      return const Color(0xFF4CAF50); // Green
    } else if (progress > 0.3) {
      return const Color(0xFFFFA726); // Orange
    } else {
      return const Color(0xFFEF5350); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress ring
        SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: remainingMessages / totalMessages,
              progressColor: _getProgressColor(),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              strokeWidth: 3.0,
            ),
          ),
        ),
        // Original send button (slightly smaller to fit inside ring) with glass styling
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: canSend
                      ? [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.15),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.0,
                ),
                boxShadow: canSend
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: IconButton(
                onPressed: canSend ? onPressed : null,
                icon: Icon(
                  Icons.send,
                  color: canSend ? AppColors.primaryText : AppColors.tertiaryText,
                  size: ResponsiveUtils.iconSize(context, 18),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        // Message count badge (bottom right)
        if (remainingMessages > 0 && remainingMessages <= 10)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getProgressColor(),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$remainingMessages',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for the circular progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
