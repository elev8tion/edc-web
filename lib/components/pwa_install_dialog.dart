import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';
import 'glass_card.dart';
import 'glass_effects/glass_dialog.dart';
import '../theme/app_theme_extensions.dart';
import '../core/services/pwa_install_service.dart';

/// PWA Install Dialog widget for use with showDialog
///
/// This is a simpler widget that can be used directly with showDialog()
/// for more control over the dialog lifecycle.
class PwaInstallDialog extends StatefulWidget {
  final VoidCallback onInstall;
  final VoidCallback onDismiss;
  final bool isIOS;

  const PwaInstallDialog({
    super.key,
    required this.onInstall,
    required this.onDismiss,
    this.isIOS = false,
  });

  @override
  State<PwaInstallDialog> createState() => _PwaInstallDialogState();
}

class _PwaInstallDialogState extends State<PwaInstallDialog> {
  bool _isInstalling = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.3),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.download_rounded,
                color: AppTheme.goldColor,
                size: ResponsiveUtils.scaleSize(context, 36,
                    minScale: 0.8, maxScale: 1.3),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              l10n.pwaInstallTitle,
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.fontSize(context, 22,
                    minSize: 18, maxSize: 26),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              l10n.pwaInstallDescription,
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: ResponsiveUtils.fontSize(context, 14,
                    minSize: 12, maxSize: 16),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features list
            _buildFeature(context, Icons.speed_outlined, l10n.pwaFeatureFast),
            const SizedBox(height: 10),
            _buildFeature(
                context, Icons.home_outlined, l10n.pwaFeatureHomeScreen),

            const SizedBox(height: 16),

            // Private browsing warning
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.secondaryText.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.pwaPrivateModeWarning,
                    style: TextStyle(
                      color: AppColors.secondaryText.withValues(alpha: 0.7),
                      fontSize: ResponsiveUtils.fontSize(context, 11,
                          minSize: 10, maxSize: 12),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Show different content for iOS vs Android/Desktop
            if (widget.isIOS) ...[
              // iOS Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.pwaIOSInstructions,
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: ResponsiveUtils.fontSize(context, 14,
                            minSize: 12, maxSize: 16),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Step 1: Tap share and add to home screen
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.ios_share,
                            color: AppTheme.goldColor, size: 24),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward,
                            color: AppColors.secondaryText, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          l10n.pwaIOSAddToHomeScreen,
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: ResponsiveUtils.fontSize(context, 13,
                                minSize: 11, maxSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Step 2: Exit browser and open from icon
                    Text(
                      l10n.pwaExitBrowserInstruction,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: ResponsiveUtils.fontSize(context, 12,
                            minSize: 10, maxSize: 14),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassDialogButton(
                text: l10n.pwaGotIt,
                isPrimary: true,
                onTap: widget.onDismiss,
              ),
            ] else ...[
              // Android/Desktop - Show install button
              Row(
                children: [
                  Expanded(
                    child: GlassDialogButton(
                      text: l10n.pwaNotNow,
                      onTap: widget.onDismiss,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isInstalling
                        ? Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                              borderRadius: AppRadius.largeCardRadius,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.goldColor,
                                ),
                              ),
                            ),
                          )
                        : GlassDialogButton(
                            text: l10n.pwaInstallButton,
                            isPrimary: true,
                            color: AppTheme.goldColor,
                            onTap: () {
                              setState(() => _isInstalling = true);
                              widget.onInstall();
                            },
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.goldColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the PWA install prompt dialog using glass morphism style
/// Returns true if user initiated install, false if dismissed
Future<bool?> showPWAInstallDialog(BuildContext context, {bool isIOS = false}) {
  return showGlassDialog<bool>(
    context: context,
    barrierDismissible: true,
    child: _PWAInstallDialogContent(isIOS: isIOS),
  );
}

class _PWAInstallDialogContent extends StatefulWidget {
  final bool isIOS;

  const _PWAInstallDialogContent({this.isIOS = false});

  @override
  State<_PWAInstallDialogContent> createState() =>
      _PWAInstallDialogContentState();
}

class _PWAInstallDialogContentState extends State<_PWAInstallDialogContent> {
  bool _isInstalling = false;
  final _pwaService = PwaInstallService();

  Future<void> _handleInstall() async {
    if (_isInstalling) return;

    setState(() => _isInstalling = true);

    try {
      final installed = await _pwaService.promptInstall();

      if (mounted) {
        if (installed) {
          debugPrint('[PWA] Install prompt accepted');
          Navigator.pop(context, true);
        } else {
          debugPrint('[PWA] Install prompt dismissed or failed');
          // Show a snackbar that install was cancelled
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pwaAlreadyInstalled),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          Navigator.pop(context, false);
        }
      }
    } catch (e) {
      debugPrint('[PWA] Install failed: $e');
      if (mounted) {
        setState(() => _isInstalling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  AppTheme.goldColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.download_rounded,
              color: AppTheme.goldColor,
              size: ResponsiveUtils.scaleSize(context, 36,
                  minScale: 0.8, maxScale: 1.3),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            l10n.pwaInstallTitle,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveUtils.fontSize(context, 22,
                  minSize: 18, maxSize: 26),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            l10n.pwaInstallDescription,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Features list
          _buildFeature(context, Icons.speed_outlined, l10n.pwaFeatureFast),
          const SizedBox(height: 10),
          _buildFeature(
              context, Icons.home_outlined, l10n.pwaFeatureHomeScreen),

          const SizedBox(height: 16),

          // Private browsing warning (applies to all browsers)
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.secondaryText.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pwaPrivateModeWarning,
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.7),
                    fontSize: ResponsiveUtils.fontSize(context, 11,
                        minSize: 10, maxSize: 12),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Show different content for iOS vs Android/Desktop
          if (widget.isIOS) ...[
            // iOS Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.pwaIOSInstructions,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: ResponsiveUtils.fontSize(context, 14,
                          minSize: 12, maxSize: 16),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Step 1: Tap share and add to home screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.ios_share,
                          color: AppTheme.goldColor, size: 24),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: AppColors.secondaryText, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        l10n.pwaIOSAddToHomeScreen,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: ResponsiveUtils.fontSize(context, 13,
                              minSize: 11, maxSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Step 2: Exit browser and open from icon
                  Text(
                    l10n.pwaExitBrowserInstruction,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: ResponsiveUtils.fontSize(context, 12,
                          minSize: 10, maxSize: 14),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassDialogButton(
              text: l10n.pwaGotIt,
              isPrimary: true,
              onTap: () => Navigator.pop(context, false),
            ),
          ] else ...[
            // Android/Desktop - Show install button
            Row(
              children: [
                Expanded(
                  child: GlassDialogButton(
                    text: l10n.pwaNotNow,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isInstalling
                      ? Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(alpha: 0.3),
                            borderRadius: AppRadius.largeCardRadius,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.goldColor,
                              ),
                            ),
                          ),
                        )
                      : GlassDialogButton(
                          text: l10n.pwaInstallButton,
                          isPrimary: true,
                          color: AppTheme.goldColor,
                          onTap: _handleInstall,
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.goldColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
