import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data model for popup menu items
class BlurPopupMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;

  const BlurPopupMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
  });
}

/// Glassmorphic popup menu with full-screen backdrop blur
class BlurPopupMenu extends StatefulWidget {
  final List<BlurPopupMenuItem> items;
  final ValueChanged<String> onSelected;
  final Widget child;
  final double menuWidth;
  final double itemSpacing;

  const BlurPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.menuWidth = 200,
    this.itemSpacing = 8,
  });

  @override
  State<BlurPopupMenu> createState() => _BlurPopupMenuState();
}

class _BlurPopupMenuState extends State<BlurPopupMenu> {
  OverlayEntry? _overlayEntry;

  void _showMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeMenu,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Full-screen backdrop blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.transparent),
                ),
              ),
              // Popup menu container
              Positioned(
                left: offset.dx - widget.menuWidth + size.width,
                top: offset.dy + size.height + 5,
                width: widget.menuWidth,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: AppRadius.largeCardRadius,
                      border: Border.all(
                        color: AppTheme.goldColor,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < widget.items.length; i++) ...[
                          _buildMenuItem(widget.items[i]),
                          if (i < widget.items.length - 1)
                            _buildDivider(),
                        ],
                      ],
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
  }

  Widget _buildMenuItem(BlurPopupMenuItem item) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.largeCardRadius,
      child: InkWell(
        borderRadius: AppRadius.largeCardRadius,
        onTap: () {
          widget.onSelected(item.value);
          _removeMenu();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: item.iconColor ?? Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_overlayEntry != null) {
          _removeMenu();
        } else {
          _showMenu();
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }
}
