import 'package:flutter/material.dart';
import 'package:flutter_pwa_install/flutter_pwa_install.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';
import 'glass_card.dart';
import 'glass_effects/glass_dialog.dart';

/// Shows the PWA install prompt dialog
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

  Future<void> _handleInstall() async {
    if (_isInstalling) return;

    setState(() => _isInstalling = true);

    try {
      final pwa = FlutterPWAInstall.instance;
      final canInstall = await pwa.canInstall();

      if (canInstall) {
        debugPrint('[PWA] Triggering install prompt from dialog button');
        await pwa.promptInstall();
        if (mounted) Navigator.pop(context, true);
      } else {
        debugPrint('[PWA] Cannot install - may already be installed');
        if (mounted) {
          // Show a snackbar that app may already be installed
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
          _buildFeature(
              context, Icons.offline_bolt_outlined, l10n.pwaFeatureOffline),
          const SizedBox(height: 10),
          _buildFeature(context, Icons.speed_outlined, l10n.pwaFeatureFast),
          const SizedBox(height: 10),
          _buildFeature(
              context, Icons.home_outlined, l10n.pwaFeatureHomeScreen),

          const SizedBox(height: 24),

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
