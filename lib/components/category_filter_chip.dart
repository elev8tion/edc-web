import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../core/models/prayer_category.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';

class CategoryFilterChip extends StatefulWidget {
  final PrayerCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryFilterChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<CategoryFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final _audio = UIAudio();

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0), // Driven by spring physics
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Haptic & audio feedback
    HapticFeedback.selectionClick();
    _audio.playTick();

    // Spring pop animation
    _scaleController.animateWith(
      SpringSimulation(
        MotionCharacter.playful,
        _scaleController.value,
        1.05,
        0,
      ),
    ).then((_) {
      // Spring back
      _scaleController.animateWith(
        SpringSimulation(
          MotionCharacter.playful,
          _scaleController.value,
          1.0,
          0,
        ),
      );
    });

    widget.onTap();
  }

  String _getLocalizedCategoryName(BuildContext context, String englishName) {
    final l10n = AppLocalizations.of(context);
    switch (englishName.toLowerCase()) {
      case 'family':
        return l10n.family;
      case 'health':
        return l10n.health;
      case 'work':
        return l10n.work;
      case 'ministry':
        return l10n.ministry;
      case 'thanksgiving':
        return l10n.thanksgiving;
      case 'intercession':
        return l10n.intercession;
      case 'finances':
        return l10n.finances;
      case 'relationships':
        return l10n.relationships;
      case 'guidance':
        return l10n.guidance;
      case 'protection':
        return l10n.protection;
      case 'general':
        return l10n.general;
      case 'faith':
        return l10n.faith;
      case 'gratitude':
        return l10n.gratitude;
      case 'other':
        return l10n.other;
      default:
        return englishName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      widget.category.color.withValues(alpha: 0.4),
                      widget.category.color.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: AppRadius.largeCardRadius,
            border: Border.all(
              color: widget.isSelected
                  ? widget.category.color
                  : Colors.white.withValues(alpha: 0.2),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.category.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.category.icon,
                size: 16,
                color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                _getLocalizedCategoryName(context, widget.category.name),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
