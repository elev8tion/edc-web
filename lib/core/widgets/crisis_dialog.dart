/// Crisis Dialog Widget
/// Non-dismissible dialog shown when crisis is detected
/// Provides immediate access to crisis resources and hotlines

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../services/crisis_detection_service.dart';
import '../../theme/app_theme.dart';
import '../../components/frosted_glass_card.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/blur_dialog_utils.dart';

/// Non-dismissible crisis intervention dialog
class CrisisDialog extends StatelessWidget {
  final CrisisDetectionResult crisisResult;
  final VoidCallback onAcknowledge;

  const CrisisDialog({
    Key? key,
    required this.crisisResult,
    required this.onAcknowledge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLanguage = l10n.localeName;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.3),
                            Colors.red.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: ResponsiveUtils.iconSize(context, 24),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.crisisResources,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 20, minSize: 18, maxSize: 24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Crisis message
                        Text(
                          crisisResult.getMessage(language: currentLanguage),
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Hotline button
                        _buildHotlineButton(context, currentLanguage),

                        const SizedBox(height: AppSpacing.lg),

                        // Additional resources
                        _buildAdditionalResources(context),

                        const SizedBox(height: AppSpacing.xl),

                        // Important notice
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: ResponsiveUtils.iconSize(context, 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  l10n.crisisImmediateDanger,
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.fontSize(context, 13, minSize: 11, maxSize: 15),
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Acknowledge button (only way to dismiss)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAcknowledge();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      foregroundColor: AppColors.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(
                      l10n.crisisAcknowledge,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build primary hotline call button
  Widget _buildHotlineButton(BuildContext context, String language) {
    final hotline = crisisResult.getHotline(language: language);
    final isPhoneNumber = hotline.startsWith('988') || hotline.startsWith('800');

    // Get localized button text
    String buttonText;
    if (isPhoneNumber) {
      buttonText = language == 'es' ? 'Llamar al $hotline Ahora' : 'Call $hotline Now';
    } else {
      buttonText = hotline;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _callHotline(context, hotline),
        icon: Icon(isPhoneNumber ? Icons.phone : Icons.message, size: 24),
        label: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.smallRadius,
          ),
        ),
      ),
    );
  }

  /// Build additional crisis resources section
  Widget _buildAdditionalResources(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.additionalResources,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildResourceTile(
          context: context,
          icon: Icons.chat_bubble_outline,
          title: l10n.crisisTextLine,
          subtitle: l10n.crisisTextLineDesc,
          onTap: () => _launchSMS('741741', 'HOME'),
        ),
        if (crisisResult.type == CrisisType.suicide) ...[
          _buildResourceTile(
            context: context,
            icon: Icons.language,
            title: l10n.lifeline988Website,
            subtitle: l10n.lifeline988Chat,
            onTap: () => _launchURL('https://988lifeline.org'),
          ),
        ],
        if (crisisResult.type == CrisisType.abuse) ...[
          _buildResourceTile(
            context: context,
            icon: Icons.language,
            title: l10n.rainnOnlineChat,
            subtitle: l10n.rainnWebsite,
            onTap: () => _launchURL('https://www.rainn.org/get-help'),
          ),
        ],
      ],
    );
  }

  /// Build a resource list tile
  Widget _buildResourceTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: ResponsiveUtils.iconSize(context, 20),
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtils.fontSize(context, 14, minSize: 12, maxSize: 16),
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 12, minSize: 10, maxSize: 14),
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: ResponsiveUtils.iconSize(context, 14),
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Call crisis hotline
  Future<void> _callHotline(BuildContext context, String hotline) async {
    String number;

    if (hotline == '988') {
      number = 'tel:988';
    } else if (hotline.startsWith('800')) {
      number = 'tel:$hotline';
    } else if (hotline.contains('741741')) {
      await _launchSMS('741741', 'HOME');
      return;
    } else {
      return;
    }

    final uri = Uri.parse(number);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showErrorSnackbar(context, 'Unable to make call. Please dial $hotline manually.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error: ${e.toString()}');
      }
    }
  }

  /// Launch SMS to crisis text line
  Future<void> _launchSMS(String number, String body) async {
    final uri = Uri.parse('sms:$number?body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Silently fail - user can manually text
    }
  }

  /// Launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  /// Show crisis dialog
  static Future<void> show(
    BuildContext context, {
    required CrisisDetectionResult crisisResult,
    required VoidCallback onAcknowledge,
  }) {
    return showBlurredDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (context) => CrisisDialog(
        crisisResult: crisisResult,
        onAcknowledge: onAcknowledge,
      ),
    );
  }
}
