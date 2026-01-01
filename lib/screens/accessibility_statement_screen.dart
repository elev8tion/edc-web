import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/frosted_glass_card.dart';
import '../components/gradient_background.dart';
import '../components/glass_button.dart';
import '../core/navigation/navigation_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';

/// Accessibility Statement screen for WCAG 2.1 AA compliance disclosure
/// Displays commitment to accessibility, measures taken, and known limitations
class AccessibilityStatementScreen extends StatelessWidget {
  const AccessibilityStatementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCommitmentSection(context, l10n),
                        const SizedBox(height: 24),
                        _buildConformanceSection(context, l10n),
                        const SizedBox(height: 24),
                        _buildMeasuresSection(context, l10n),
                        const SizedBox(height: 24),
                        _buildLimitationsSection(context, l10n),
                        const SizedBox(height: 24),
                        _buildFeedbackSection(context, l10n),
                        const SizedBox(height: 24),
                        _buildLastUpdated(context, l10n),
                        const SizedBox(height: 32),
                        _buildBackButton(context, l10n),
                        const SizedBox(height: 24),
                      ],
                    )
                        .animate()
                        .fadeIn(
                            duration: AppAnimations.slow,
                            delay: AppAnimations.fast)
                        .slideY(begin: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => NavigationService.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.accessibilityStatement,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.goldColor.withValues(alpha: 0.3),
                  AppTheme.goldColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: AppTheme.goldColor,
              size: 24,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: -0.3);
  }

  Widget _buildCommitmentSection(BuildContext context, AppLocalizations l10n) {
    return _buildSection(
      context: context,
      icon: Icons.favorite,
      iconColor: Colors.pink,
      title: l10n.accessibilityCommitmentTitle,
      content: l10n.accessibilityCommitment,
    );
  }

  Widget _buildConformanceSection(BuildContext context, AppLocalizations l10n) {
    return _buildSection(
      context: context,
      icon: Icons.verified,
      iconColor: Colors.green,
      title: l10n.accessibilityConformanceTitle,
      content: l10n.accessibilityConformance,
    );
  }

  Widget _buildMeasuresSection(BuildContext context, AppLocalizations l10n) {
    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: Colors.blue.withValues(alpha: 0.8),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.accessibilityMeasures,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMeasureItem(context, Icons.code, l10n.measureSemanticHtml),
            _buildMeasureItem(
                context, Icons.contrast, l10n.measureColorContrast),
            _buildMeasureItem(
                context, Icons.touch_app, l10n.measureTouchTargets),
            _buildMeasureItem(context, Icons.keyboard, l10n.measureKeyboardNav),
            _buildMeasureItem(context, Icons.image, l10n.measureAltText),
            _buildMeasureItem(
                context, Icons.text_fields, l10n.measureScalableText),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.green.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitationsSection(BuildContext context, AppLocalizations l10n) {
    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.withValues(alpha: 0.8),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.accessibilityLimitations,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLimitationItem(context, l10n.limitationStripeCheckout),
            _buildLimitationItem(context, l10n.limitationComplexCharts),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: Colors.orange.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, AppLocalizations l10n) {
    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: AppTheme.goldColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.feedbackTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.accessibilityFeedback,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchEmail(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail,
                      color: AppTheme.goldColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'support@everydaychristian.app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.goldColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.goldColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.lastUpdated('January 2026'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, AppLocalizations l10n) {
    return GlassButton(
      text: l10n.backToSettings,
      onPressed: () => NavigationService.pop(),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor.withValues(alpha: 0.8),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse(
        'mailto:support@everydaychristian.app?subject=Accessibility%20Feedback');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
