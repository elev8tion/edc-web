import 'dart:math';
import 'package:flutter/material.dart';

/// StaticNoiseOverlay - Adds subtle grain texture to glass surfaces
///
/// Creates a realistic glass effect by applying a random static noise pattern.
/// The noise is deterministic (seeded) so it stays consistent across rebuilds.
class StaticNoiseOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double density;

  const StaticNoiseOverlay({
    super.key,
    required this.child,
    this.opacity = 0.06,
    this.density = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StaticNoisePainter(opacity: opacity, density: density),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaticNoisePainter extends CustomPainter {
  final double opacity;
  final double density;
  final Random _random = Random(42); // Seeded for consistency

  _StaticNoisePainter({required this.opacity, required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    final pointCount = (size.width * size.height * density / 100).toInt();

    for (int i = 0; i < pointCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final brightness = _random.nextDouble();
      paint.color = Colors.white.withValues(alpha: brightness * opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_StaticNoisePainter oldDelegate) => false;
}
