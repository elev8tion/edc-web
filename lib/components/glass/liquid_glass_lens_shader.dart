import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'base_shader.dart';

class LiquidGlassLensShader extends BaseShader {
  LiquidGlassLensShader()
      : super(shaderAssetPath: 'shaders/liquid_glass_lens.frag');

  @override
  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
  }) {
    if (!isLoaded) return;

    shader.setFloat(0, width);   // uResolution.x
    shader.setFloat(1, height);  // uResolution.y
    shader.setFloat(2, width / 2);  // uMouse.x (center)
    shader.setFloat(3, height / 2); // uMouse.y (center)
    shader.setFloat(4, 5.0);     // uEffectSize
    shader.setFloat(5, 0.0);     // uBlurIntensity
    shader.setFloat(6, 0.4);     // uDispersionStrength

    if (backgroundImage != null &&
        backgroundImage.width > 0 &&
        backgroundImage.height > 0) {
      try {
        shader.setImageSampler(0, backgroundImage);
      } catch (e) {
        debugPrint('Error setting background texture: $e');
      }
    }
  }
}
