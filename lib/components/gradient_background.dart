import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final List<Color>? colors;
  final List<double>? stops;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final double? blurSigmaX;
  final double? blurSigmaY;

  const GradientBackground({
    super.key,
    this.colors,
    this.stops,
    this.begin,
    this.end,
    this.blurSigmaX,
    this.blurSigmaY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? const [
            Color(0xFF1A1A2E), // Dark navy from our theme
            AppTheme.primaryColor, // Our indigo
            AppTheme.accentColor, // Our purple
            Color(0xFF0F3460), // Deep dark blue from our theme
          ],
          stops: stops ?? const [0, 0.3, 0.7, 1],
          begin: begin ?? const Alignment(-1, 0.5),
          end: end ?? const Alignment(1, -0.5),
        ),
      ),
    );
  }
}