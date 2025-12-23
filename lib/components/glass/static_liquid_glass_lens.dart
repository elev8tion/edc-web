import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'liquid_glass_lens_shader.dart';
import 'shader_painter.dart';

/// A simplified liquid glass lens widget that works inline within scrollable content.
/// Unlike BackgroundCaptureWidget, this doesn't use Positioned/Draggable.
class StaticLiquidGlassLens extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double effectSize;
  final double blurIntensity;
  final double dispersionStrength;
  final GlobalKey? backgroundKey;
  final Duration captureInterval;

  const StaticLiquidGlassLens({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.effectSize = 5.0,
    this.blurIntensity = 0.0,
    this.dispersionStrength = 0.4,
    this.backgroundKey,
    this.captureInterval = const Duration(milliseconds: 100), // 10fps - reduced to prevent iOS crashes
  });

  @override
  State<StaticLiquidGlassLens> createState() => _StaticLiquidGlassLensState();
}

class _StaticLiquidGlassLensState extends State<StaticLiquidGlassLens> {
  late LiquidGlassLensShader shader;
  Timer? captureTimer;
  bool isCapturing = false;
  ui.Image? capturedBackground;

  @override
  void initState() {
    super.initState();
    shader = LiquidGlassLensShader()..initialize();

    // Start periodic background capture
    _startContinuousCapture();

    // Initial capture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureBackground();
    });
  }

  @override
  void dispose() {
    captureTimer?.cancel();
    capturedBackground?.dispose();
    super.dispose();
  }

  void _startContinuousCapture() {
    captureTimer = Timer.periodic(widget.captureInterval, (timer) {
      if (mounted && !isCapturing) {
        _captureBackground();
      }
    });
  }

  Future<void> _captureBackground() async {
    if (isCapturing || !mounted) return;

    isCapturing = true;

    try {
      // Get the RepaintBoundary from the backgroundKey
      final boundary = widget.backgroundKey?.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      // Get our own RenderBox to calculate position
      final ourBox = context.findRenderObject() as RenderBox?;

      if (boundary == null ||
          !boundary.attached ||
          ourBox == null ||
          !ourBox.hasSize) {
        return;
      }

      // Calculate dimensions
      final boundaryBox = boundary as RenderBox;
      if (!boundaryBox.hasSize) return;

      final widgetWidth = widget.width ?? ourBox.size.width;
      final widgetHeight = widget.height ?? ourBox.size.height;

      if (widgetWidth <= 0 || widgetHeight <= 0) return;

      // Calculate the region to capture (our widget's position within the boundary)
      final widgetRectInBoundary = Rect.fromPoints(
        boundaryBox.globalToLocal(ourBox.localToGlobal(Offset.zero)),
        boundaryBox.globalToLocal(
          ourBox.localToGlobal(Offset(widgetWidth, widgetHeight)),
        ),
      );

      final boundaryRect = Rect.fromLTWH(
        0,
        0,
        boundaryBox.size.width,
        boundaryBox.size.height,
      );

      final regionToCapture = widgetRectInBoundary.intersect(boundaryRect);

      if (regionToCapture.isEmpty) return;

      // Check if debugLayer is available
      if (boundary.debugLayer == null) {
        debugPrint('StaticLiquidGlassLens: debugLayer not ready yet');
        return;
      }

      // Capture the image
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final offsetLayer = boundary.debugLayer! as OffsetLayer;
      final croppedImage = await offsetLayer.toImage(
        regionToCapture,
        pixelRatio: pixelRatio,
      );

      // Update state
      if (mounted) {
        setState(() {
          capturedBackground?.dispose();
          capturedBackground = croppedImage;
        });
      } else {
        croppedImage.dispose();
      }
    } catch (e) {
      debugPrint('StaticLiquidGlassLens: Error capturing background: $e');
    } finally {
      if (mounted) {
        isCapturing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to get actual dimensions if not provided
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetWidth = widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0);
        final widgetHeight = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 150.0);

        // If shader is loaded and we have a captured background, render the effect
        if (shader.isLoaded && capturedBackground != null) {
          shader.updateShaderUniforms(
            width: widgetWidth,
            height: widgetHeight,
            backgroundImage: capturedBackground,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(40), // Rounded corners to hide RepaintBoundary artifacts
            child: CustomPaint(
              size: Size(widgetWidth, widgetHeight),
              painter: ShaderPainter(shader.shader),
              child: widget.child,
            ),
          );
        }

        // Fallback: just show the child without effect
        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: widget.child,
        );
      },
    );
  }
}
