import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/app_theme.dart';
import 'glass/static_liquid_glass_lens.dart';
import 'category_badge.dart';
import 'dark_glass_container.dart';

class DailyVerseWithGlassDecoration extends HookWidget {
  final String verse;
  final String reference;
  final GlobalKey backgroundKey;

  const DailyVerseWithGlassDecoration({
    super.key,
    required this.verse,
    required this.reference,
    required this.backgroundKey,
  });

  @override
  Widget build(BuildContext context) {
    // Animation controller for glass decoration fade-in
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final fadeAnimation = useAnimation(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Track mounted state for safe delayed callback
    final isMounted = useRef(true);

    // Trigger animation on mount with safety check
    useEffect(() {
      isMounted.value = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        // Safety check: only forward if still mounted
        if (isMounted.value) {
          try {
            animationController.forward();
          } catch (_) {
            // Controller was disposed, ignore
          }
        }
      });
      return () {
        isMounted.value = false;
      };
    }, []);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main verse card with original styling
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldColor.withValues(alpha: 0.3),
                          AppTheme.goldColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: AppRadius.mediumRadius,
                      border: Border.all(
                        color: AppTheme.goldColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Verse of the Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: AppTheme.textShadowStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DarkGlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: AppRadius.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verse,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        shadows: AppTheme.textShadowSubtle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reference,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.goldColor,
                            fontWeight: FontWeight.w700,
                            shadows: AppTheme.textShadowSubtle,
                          ),
                        ),
                        const CategoryBadge(
                          text: 'Comfort',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Decorative liquid glass element - positioned behind/offset
        Positioned(
          top: -30,
          right: -30,
          child: Opacity(
            opacity: fadeAnimation * 0.8,
            child: StaticLiquidGlassLens(
              backgroundKey: backgroundKey,
              width: 150,
              height: 150,
              effectSize: 4.0,
              dispersionStrength: 0.4,
              blurIntensity: 0.08,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
