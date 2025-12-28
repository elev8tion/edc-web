import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import 'glass_card.dart';
import 'glass_effects/glass_dialog.dart';

/// Shows the app update dialog
/// Returns true if user chose to refresh, false if dismissed
Future<bool?> showAppUpdateDialog(BuildContext context) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: false, // User must choose an option
    child: const _AppUpdateDialogContent(),
  );
}

class _AppUpdateDialogContent extends StatelessWidget {
  const _AppUpdateDialogContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.3),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.system_update_outlined,
              color: AppTheme.primaryColor,
              size: ResponsiveUtils.scaleSize(context, 32, minScale: 0.8, maxScale: 1.3),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          AutoSizeText(
            l10n.updateAvailableTitle,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            l10n.updateAvailableDescription,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GlassDialogButton(
                  text: l10n.updateLater,
                  onTap: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassDialogButton(
                  text: l10n.updateNow,
                  isPrimary: true,
                  onTap: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
