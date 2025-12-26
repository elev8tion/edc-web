import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../theme/app_theme.dart';
import '../core/navigation/app_routes.dart';
import '../core/navigation/navigation_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';
import '../l10n/app_localizations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'glass_card.dart';

/// Glassmorphic Floating Action Button Menu
///
/// A modern, brand-focused navigation menu that replaces traditional drawers.
/// Features:
/// - App logo instead of generic icon
/// - Full-screen backdrop blur when open
/// - Glassmorphic styled menu items
/// - Smooth animations
/// - Responsive sizing
/// - Haptic feedback
class GlassmorphicFABMenu extends StatefulWidget {
  final VoidCallback? onMenuOpened;

  const GlassmorphicFABMenu({super.key, this.onMenuOpened});

  @override
  State<GlassmorphicFABMenu> createState() => _GlassmorphicFABMenuState();
}

class _GlassmorphicFABMenuState extends State<GlassmorphicFABMenu>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fabController;
  final _audio = UIAudio();
  bool _isVisible = false;
  OverlayEntry? _overlayEntry;

  // Menu items matching your app routes (now a method to access l10n)
  List<MenuOption> _getMenuOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      MenuOption(
        title: l10n.homeScreen, // "Home" / "Inicio"
        icon: Icons.home,
        color: AppTheme.goldColor,
        route: AppRoutes.home,
      ),
      MenuOption(
        title: l10n.bibleBrowser, // "Bible Browser"
        icon: Icons.menu_book,
        color: Colors.orange,
        route: AppRoutes.bibleBrowser,
      ),
      MenuOption(
        title: l10n.biblicalChat, // "Biblical Chat"
        icon: Icons.chat_bubble_outline,
        color: Colors.blue,
        route: AppRoutes.chat,
      ),
      MenuOption(
        title: l10n.prayerJournal, // "Prayer Journal"
        icon: Icons.favorite_outline,
        color: Colors.red,
        route: AppRoutes.prayerJournal,
      ),
      MenuOption(
        title: l10n.dailyDevotional, // "Daily Devotional"
        icon: Icons.auto_stories,
        color: Colors.green,
        route: AppRoutes.devotional,
      ),
      MenuOption(
        title: l10n.readingPlans, // "Reading Plans"
        icon: Icons.library_books_outlined,
        color: Colors.purple,
        route: AppRoutes.readingPlan,
      ),
      MenuOption(
        title: l10n.verseLibrary, // "Verse Library"
        icon: Icons.search,
        color: AppTheme.goldColor,
        route: AppRoutes.verseLibrary,
      ),
      MenuOption(
        title: l10n.profile, // "Profile"
        icon: Icons.person_outline,
        color: Colors.teal,
        route: AppRoutes.profile,
      ),
      MenuOption(
        title: l10n.settings, // "Settings"
        icon: Icons.settings_outlined,
        color: Colors.grey,
        route: AppRoutes.settings,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabController = AnimationController(
      vsync: this,
      value: 1.0, // Start visible
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    // Ensure overlay is removed immediately on dispose, regardless of animation state
    _removeOverlay();
    _controller.stop(); // Stop any running animation first
    _controller.dispose();
    _fabController.stop();
    _fabController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.mediumImpact();
    _audio.playClick();

    if (!mounted) return;

    setState(() {
      _isVisible = !_isVisible;
    });

    if (_isVisible) {
      _showOverlay();
      _audio.playWhoosh();
      // Menu items expand with smooth spring
      _controller.animateWith(
        SpringSimulation(MotionCharacter.smooth, _controller.value, 1.0, 0),
      );
      // FAB shrinks with snappy spring
      _fabController.animateWith(
        SpringSimulation(MotionCharacter.snappy, _fabController.value, 0.0, 0),
      );
      // Notify that menu was opened (for first-time user tutorial)
      widget.onMenuOpened?.call();
    } else {
      _audio.playWhoosh();
      // Menu items collapse with smooth spring
      _controller.animateWith(
        SpringSimulation(MotionCharacter.smooth, _controller.value, 0.0, 0),
      ).then((_) {
        // Safety check: only remove overlay if still mounted
        if (mounted) {
          _removeOverlay();
        }
      });
      // FAB returns with playful bounce
      _fabController.animateWith(
        SpringSimulation(MotionCharacter.playful, _fabController.value, 1.0, 0),
      );
    }
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildOverlay() {
    return GestureDetector(
      onTap: _toggleMenu,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Full-screen backdrop blur (matches blur_dropdown.dart)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _controller.value,
                  duration: const Duration(milliseconds: 300),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _controller.value * 8,
                      sigmaY: _controller.value * 8,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3 * _controller.value),
                    ),
                  ),
                ),
              ),
              // Animated menu items
              ..._buildAnimatedMenuItems(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildAnimatedMenuItems() {
    // Safety check: don't build if widget is disposed
    if (!mounted) return [];

    final options = _getMenuOptions(context);

    // Position from top-left where FAB is located
    final double leftPadding = ResponsiveUtils.scaleSize(context, 20, minScale: 0.8, maxScale: 1.2);
    final double topPadding = ResponsiveUtils.scaleSize(context, 70, minScale: 0.9, maxScale: 1.1); // Below FAB

    const double itemHeight = 48.0;
    const double gap = 8.0;
    const double itemSpacing = itemHeight + gap;

    return List.generate(options.length, (index) {
      final option = options[index];
      final double staggerDelay = index * 0.025;

      // Phase 1: Icon appears (icons slide in first)
      final iconAppearAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(staggerDelay, 0.4 + staggerDelay, curve: Curves.easeOutCubic),
        ),
      );

      // Phase 2: Expand to show text (then container expands to reveal text)
      final expandAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.3 + staggerDelay, 0.65 + staggerDelay, curve: Curves.easeOutCubic),
        ),
      );

      return Positioned(
        top: topPadding + (itemSpacing * index * iconAppearAnimation.value),
        left: leftPadding,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: iconAppearAnimation.value,
          child: Opacity(
            opacity: iconAppearAnimation.value,
            child: _buildMenuItem(option, expandAnimation.value, index),
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem(MenuOption option, double expandProgress, int index) {
    const double iconSize = 32.0;
    const double containerPadding = 16.0; // horizontal: 8 on each side = 16 total
    const double collapsedWidth = iconSize + containerPadding + 4.0; // 52px (extra 4px for spacing/rounding)
    final double expandedWidth = ResponsiveUtils.scaleSize(context, 200, minScale: 0.85, maxScale: 1.2);
    // Clamp to prevent spring animation overshoot from making width too small
    final double currentWidth = (collapsedWidth + (expandedWidth - collapsedWidth) * expandProgress).clamp(collapsedWidth, expandedWidth);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _audio.playTick();
        final route = option.route;
        _toggleMenu();

        // Navigate after menu animation completes
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // Remove overlay BEFORE navigation to prevent orphaning
            _removeOverlay();

            HapticFeedback.mediumImpact();
            _audio.playConfirm();

            // Use NavigationService for debounced navigation
            if (route == AppRoutes.home) {
              NavigationService.pushAndRemoveUntil(AppRoutes.home);
            } else {
              NavigationService.pushReplacementNamed(route);
            }
          }
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          width: currentWidth,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          borderRadius: 24,
          blurStrength: 15.0,
          gradientColors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Text - fades in as container expands, hidden earlier to prevent overflow
              if (expandProgress > 0.15) // Raised threshold from 0.05 to 0.15
                Flexible(
                  child: Opacity(
                    opacity: expandProgress,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: AutoSizeText(
                        option.title,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                          shadows: AppTheme.textShadowSubtle,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              // Icon container - always visible
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(5), // Reduced from 6 to prevent overflow at high text scales
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                  border: Border.all(
                    color: option.color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  option.icon,
                  size: ResponsiveUtils.iconSize(context, 18),
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabController.value,
          child: Opacity(
            opacity: _fabController.value,
            child: GestureDetector(
              onTap: _toggleMenu,
              child: GlassContainer(
                width: ResponsiveUtils.scaleSize(context, 80, minScale: 0.85, maxScale: 1.2),
                height: ResponsiveUtils.scaleSize(context, 80, minScale: 0.85, maxScale: 1.2),
                padding: const EdgeInsets.all(8.0),
                borderRadius: 20,
                blurStrength: 15.0,
                gradientColors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
                border: Border.all(
                  color: AppTheme.goldColor,
                  width: 1.0,
                ),
                child: Center(
                  child: Image.asset(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'assets/images/logo_spanish.png'
                        : 'assets/images/logo_cropped.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if logo fails to load
                      return const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 48,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Menu option data model
class MenuOption {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  MenuOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
