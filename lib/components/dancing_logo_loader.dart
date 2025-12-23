import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/delay_tween.dart';

/// Dancing Logo Loader - Elegant 3D animated loading indicator
///
/// Features:
/// - Uses app logo (language-aware: English/Spanish)
/// - 12 glassmorphic squares arranged in 3D rotating pattern
/// - Staggered scale animations for "dancing" effect
/// - Matches FAB menu visual identity (golden gradient + blur)
/// - Smooth, continuous loop animation
class DancingLogoLoader extends StatefulWidget {
  final double size;
  final Duration duration;
  final String? languageCode;

  const DancingLogoLoader({
    super.key,
    this.size = 180.0,
    this.duration = const Duration(milliseconds: 3000),
    this.languageCode,
  });

  @override
  State<DancingLogoLoader> createState() => _DancingLogoLoaderState();
}

class _DancingLogoLoaderState extends State<DancingLogoLoader>
    with SingleTickerProviderStateMixin {
  static const _itemCount = 12;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(widget.size),
        child: Stack(
          children: List.generate(_itemCount, (index) {
            final position = widget.size * 0.5;
            final delay = index / _itemCount;

            return Stack(
              children: [
                // Top-right quadrant
                Positioned.fill(
                  left: position,
                  top: position,
                  child: Transform(
                    transform: Matrix4.rotationX(30.0 * index * 0.0174533),
                    child: Align(
                      alignment: Alignment.center,
                      child: ScaleTransition(
                        scale: DelayTween(
                          begin: 0.0,
                          end: 1.0,
                          delay: delay,
                        ).animate(_controller),
                        child: SizedBox.fromSize(
                          size: Size.square(widget.size * 0.15),
                          child: _buildGlassmorphicSquare(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Top-left quadrant
                Positioned.fill(
                  left: position,
                  top: -1 * position,
                  child: Transform(
                    transform: Matrix4.rotationY(30.0 * index * 0.0174533),
                    child: Align(
                      alignment: Alignment.center,
                      child: ScaleTransition(
                        scale: DelayTween(
                          begin: 0.0,
                          end: 1.0,
                          delay: delay,
                        ).animate(_controller),
                        child: SizedBox.fromSize(
                          size: Size.square(widget.size * 0.15),
                          child: _buildGlassmorphicSquare(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom-left quadrant
                Positioned.fill(
                  left: -1 * position,
                  top: position,
                  child: Transform(
                    transform: Matrix4.rotationX(30.0 * index * 0.0174533),
                    child: Align(
                      alignment: Alignment.center,
                      child: ScaleTransition(
                        scale: DelayTween(
                          begin: 0.0,
                          end: 1.0,
                          delay: delay,
                        ).animate(_controller),
                        child: SizedBox.fromSize(
                          size: Size.square(widget.size * 0.15),
                          child: _buildGlassmorphicSquare(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom-right quadrant
                Positioned.fill(
                  left: position,
                  top: position,
                  child: Transform(
                    transform: Matrix4.rotationY(30.0 * index * 0.0174533),
                    child: Align(
                      alignment: Alignment.center,
                      child: ScaleTransition(
                        scale: DelayTween(
                          begin: 0.0,
                          end: 1.0,
                          delay: delay,
                        ).animate(_controller),
                        child: SizedBox.fromSize(
                          size: Size.square(widget.size * 0.15),
                          child: _buildGlassmorphicSquare(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Build a single glassmorphic square matching FAB menu design
  Widget _buildGlassmorphicSquare() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.goldColor.withValues(alpha: 0.3),
                AppTheme.primaryColor.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppTheme.goldColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
