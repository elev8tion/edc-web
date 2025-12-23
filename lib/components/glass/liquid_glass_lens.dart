import 'package:flutter/material.dart';
import 'background_capture_widget.dart';
import 'liquid_glass_lens_shader.dart';

class LiquidGlassLens extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double effectSize;
  final double blurIntensity;
  final double dispersionStrength;
  final GlobalKey? backgroundKey;

  const LiquidGlassLens({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.effectSize = 5.0,
    this.blurIntensity = 0.0,
    this.dispersionStrength = 0.4,
    this.backgroundKey,
  });

  @override
  State<LiquidGlassLens> createState() => _LiquidGlassLensState();
}

class _LiquidGlassLensState extends State<LiquidGlassLens> {
  late LiquidGlassLensShader shader;

  @override
  void initState() {
    super.initState();
    shader = LiquidGlassLensShader()..initialize();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundCaptureWidget(
      width: widget.width,
      height: widget.height,
      shader: shader,
      backgroundKey: widget.backgroundKey,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    // Shader cleanup handled by BackgroundCaptureWidget
    super.dispose();
  }
}
