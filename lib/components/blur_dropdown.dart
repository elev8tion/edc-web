import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../theme/app_theme.dart';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';

class BlurDropdown extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const BlurDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  State<BlurDropdown> createState() => _BlurDropdownState();
}

class _BlurDropdownState extends State<BlurDropdown>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _menuController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final _audio = UIAudio();

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0), // Driven by spring physics
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(_menuController);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_menuController);
  }

  @override
  void dispose() {
    _removeDropdown();
    _menuController.dispose();
    super.dispose();
  }

  void _showDropdown() {
    // Dismiss keyboard first
    FocusManager.instance.primaryFocus?.unfocus();

    // Haptic & audio feedback
    HapticFeedback.mediumImpact();
    _audio.playClick();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeDropdown,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Backdrop blur for entire screen
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Animated dropdown menu
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height + 5,
                width: size.width,
                child: AnimatedBuilder(
                  animation: _menuController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: AppRadius.largeCardRadius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.largeCardRadius,
                            color: Colors.black.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.goldColor,
                              width: 1,
                            ),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () {
                                  // Haptic & audio feedback on selection
                                  HapticFeedback.lightImpact();
                                  _audio.playTick();

                                  widget.onChanged(widget.items[index]);
                                  _removeDropdown();
                                },
                                onHover: (hovering) {
                                  if (hovering) {
                                    _audio.playTick();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  child: Text(
                                    widget.items[index],
                                    style: TextStyle(
                                      color: widget.value == widget.items[index]
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: widget.value == widget.items[index]
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Spring menu open animation
    _menuController.animateWith(
      SpringSimulation(
        MotionCharacter.playful,
        _menuController.value,
        1.0,
        0,
      ),
    );
  }

  void _removeDropdown() {
    // Spring menu close animation
    _menuController.animateWith(
      SpringSimulation(
        MotionCharacter.smooth,
        _menuController.value,
        0.0,
        0,
      ),
    ).then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (_overlayEntry != null) {
            _removeDropdown();
          } else {
            _showDropdown();
          }
        },
        child: ClipRRect(
          borderRadius: AppRadius.largeCardRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: AppRadius.largeCardRadius,
                color: Colors.black.withValues(alpha: 0.2),
                border: Border.all(
                  color: AppTheme.goldColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.value.isEmpty
                          ? (widget.hint ?? 'Select option')
                          : widget.value,
                      style: TextStyle(
                        color: widget.value.isEmpty
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
