import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../components/frosted_glass_card.dart';
import 'responsive_utils.dart';
import 'blur_dialog_utils.dart';

/// Reusable utility for displaying legal documents (Terms of Service, Privacy Policy)
/// across the app. Extracted from duplicated code in multiple screens.
class LegalDocumentViewer {
  /// Path to Terms of Service markdown file
  static const String termsOfServicePath = 'assets/legal/TERMS_OF_SERVICE.md';

  /// Path to Privacy Policy markdown file
  static const String privacyPolicyPath = 'assets/legal/PRIVACY_POLICY.md';

  /// Show Terms of Service dialog
  static Future<void> showTermsOfService(BuildContext context) {
    return _showDocument(
      context,
      title: 'Terms of Service',
      filePath: termsOfServicePath,
    );
  }

  /// Show Privacy Policy dialog
  static Future<void> showPrivacyPolicy(BuildContext context) {
    return _showDocument(
      context,
      title: 'Privacy Policy',
      filePath: privacyPolicyPath,
    );
  }

  /// Internal method to display a legal document in a dialog
  static Future<void> _showDocument(
    BuildContext context, {
    required String title,
    required String filePath,
  }) async {
    HapticFeedback.mediumImpact();

    String content;
    try {
      content = await rootBundle.loadString(filePath);
    } catch (e) {
      content = 'Error loading document: $e\n\nPlease contact support if this issue persists.';
    }

    if (!context.mounted) return;

    await showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
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
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Icon(
                        title == 'Terms of Service'
                          ? Icons.description
                          : Icons.privacy_tip,
                        color: AppTheme.goldColor,
                        size: ResponsiveUtils.iconSize(context, 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 20),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.primaryText),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SelectableText(
                      content,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: AppColors.secondaryText,
                        height: 1.6,
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
}
