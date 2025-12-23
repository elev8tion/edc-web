import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../components/frosted_glass_card.dart';

/// Dialog for selecting themes when favoriting a verse
/// Max 2 themes can be selected, with option to skip
class ThemeSelectionDialog extends StatefulWidget {
  final List<String> availableThemes;
  final Function(List<String>) onThemesSelected;

  const ThemeSelectionDialog({
    super.key,
    required this.availableThemes,
    required this.onThemesSelected,
  });

  @override
  State<ThemeSelectionDialog> createState() => _ThemeSelectionDialogState();
}

class _ThemeSelectionDialogState extends State<ThemeSelectionDialog> {
  final Set<String> _selectedThemes = {};
  static const int maxThemes = 2;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: ResponsiveUtils.maxContentWidth(context),
        ),
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                          AppTheme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.label_outline,
                      color: AppColors.primaryText,
                      size: ResponsiveUtils.iconSize(context, 20),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Themes',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          'Select up to 2 themes (optional)',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),

              // Selection counter
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _selectedThemes.length == maxThemes
                      ? AppTheme.goldColor.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: _selectedThemes.length == maxThemes
                        ? AppTheme.goldColor.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: ResponsiveUtils.iconSize(context, 16),
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      _selectedThemes.length == maxThemes
                          ? 'Maximum themes selected'
                          : '${_selectedThemes.length}/$maxThemes themes selected',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: _selectedThemes.length == maxThemes
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Scrollable theme list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.availableThemes.map((theme) {
                      final isSelected = _selectedThemes.contains(theme);
                      final canSelect = _selectedThemes.length < maxThemes || isSelected;

                      return Opacity(
                        opacity: canSelect ? 1.0 : 0.4,
                        child: Container(
                          margin: EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.goldColor.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canSelect
                                  ? () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedThemes.remove(theme);
                                        } else {
                                          _selectedThemes.add(theme);
                                        }
                                      });
                                    }
                                  : null,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: canSelect
                                          ? (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedThemes.add(theme);
                                                } else {
                                                  _selectedThemes.remove(theme);
                                                }
                                              });
                                            }
                                          : null,
                                      activeColor: Colors.transparent,
                                      checkColor: AppTheme.goldColor,
                                      side: BorderSide(
                                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      shape: const CircleBorder(),
                                    ),
                                    SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        theme,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                          color: AppColors.primaryText,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  // Skip button (outline style)
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            widget.onThemesSelected([]);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Save button (GlassButton style)
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: _selectedThemes.isEmpty
                            ? null
                            : LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color: _selectedThemes.isEmpty
                            ? Colors.white.withValues(alpha: 0.05)
                            : null,
                        border: Border.all(
                          color: _selectedThemes.isEmpty
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _selectedThemes.isEmpty
                              ? null
                              : () {
                                  widget.onThemesSelected(_selectedThemes.toList());
                                  Navigator.pop(context);
                                },
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Text(
                              _selectedThemes.isEmpty
                                  ? 'Select Themes'
                                  : 'Save with ${_selectedThemes.length} theme${_selectedThemes.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                                fontWeight: FontWeight.w600,
                                color: _selectedThemes.isEmpty
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
