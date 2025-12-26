import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/preferences_service.dart';
import '../core/navigation/app_routes.dart';
import '../theme/app_theme.dart';
import '../components/frosted_glass_card.dart';
import '../components/gradient_background.dart';
import '../components/glass_button.dart';
import '../utils/legal_document_viewer.dart';
import '../l10n/app_localizations.dart';

/// Combined legal agreements screen showing crisis disclaimer and terms/privacy acceptance
/// Uses clickwrap method (checkboxes) for legally strong consent
class LegalAgreementsScreen extends StatefulWidget {
  const LegalAgreementsScreen({super.key});

  @override
  State<LegalAgreementsScreen> createState() => _LegalAgreementsScreenState();
}

class _LegalAgreementsScreenState extends State<LegalAgreementsScreen> {
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _ageChecked = false;
  bool _isAccepting = false;
  bool _isNavigating = false;

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
                _buildHeader(),
                Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroText(),
                      const SizedBox(height: 32),
                      _buildDisclaimerSection(
                        icon: Icons.health_and_safety,
                        title: l10n.notProfessionalCounseling,
                        content: l10n.notProfessionalCounselingDesc,
                      ),
                      const SizedBox(height: 24),
                      _buildCrisisResourcesSection(),
                      const SizedBox(height: 24),
                      _buildDisclaimerSection(
                        icon: Icons.gavel,
                        title: l10n.noMedicalLegalAdvice,
                        content: l10n.noMedicalLegalAdviceDesc,
                      ),
                      const SizedBox(height: 24),
                      _buildDisclaimerSection(
                        icon: Icons.smart_toy,
                        title: l10n.aiLimitations,
                        content: l10n.aiLimitationsDesc,
                      ),
                      const SizedBox(height: 24),
                      _buildDisclaimerSection(
                        icon: Icons.lightbulb_outline,
                        title: l10n.recommendedUse,
                        content: l10n.recommendedUseDesc,
                      ),
                      const SizedBox(height: 40),
                      _buildConsentSection(),
                      const SizedBox(height: 32),
                      _buildBottomButton(),
                      const SizedBox(height: 24),
                    ],
                  ).animate().fadeIn(duration: AppAnimations.slow, delay: AppAnimations.fast).slideY(begin: 0.2),
                ),
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            l10n.legalAgreements,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pleaseReviewAndAccept,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: -0.3);
  }

  Widget _buildIntroText() {
    final l10n = AppLocalizations.of(context);

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
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.importantInformation,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.legalIntroText,
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

  Widget _buildDisclaimerSection({
    required IconData icon,
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
                  color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildCrisisResourcesSection() {
    final l10n = AppLocalizations.of(context);

    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_in_talk,
                  color: Colors.red[300],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.crisisResources,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCrisisResource(
              title: l10n.crisis988Title,
              description: l10n.crisis988Desc,
              icon: Icons.phone,
              onTap: _call988,
            ),
            const SizedBox(height: 12),
            _buildCrisisResource(
              title: l10n.crisisTextLine,
              description: l10n.crisisTextLineDesc,
              icon: Icons.message,
              onTap: _textCrisisLine,
            ),
            const SizedBox(height: 12),
            _buildCrisisResource(
              title: l10n.emergencyServices,
              description: l10n.emergencyServicesDesc,
              icon: Icons.local_hospital,
              onTap: _call911,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisResource({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.red[300],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection() {
    final l10n = AppLocalizations.of(context);

    return FrostedGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.acceptanceRequired,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCheckboxTile(
              value: _termsChecked,
              onChanged: (value) {
                setState(() => _termsChecked = value ?? false);
              },
              label: l10n.haveReadAndAgree,
              linkText: l10n.termsOfService,
              onLinkTap: () => _launchURL('/terms'),
            ),
            const SizedBox(height: 12),
            _buildCheckboxTile(
              value: _privacyChecked,
              onChanged: (value) {
                setState(() => _privacyChecked = value ?? false);
              },
              label: l10n.haveReadAndAgree,
              linkText: l10n.privacyPolicy,
              onLinkTap: () => _launchURL('/privacy'),
            ),
            const SizedBox(height: 12),
            _buildSimpleCheckboxTile(
              value: _ageChecked,
              onChanged: (value) {
                setState(() => _ageChecked = value ?? false);
              },
              label: l10n.confirmAge18Plus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    final goldAccent = AppTheme.goldColor.withValues(alpha: 0.6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldAccent,
                width: 2,
              ),
              color: value ? goldAccent : Colors.transparent,
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                children: [
                  TextSpan(text: label),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.6),
                          decoration: TextDecoration.underline,
                          decorationColor: goldAccent,
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
      ],
    );
  }

  Widget _buildSimpleCheckboxTile({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    final goldAccent = AppTheme.goldColor.withValues(alpha: 0.6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldAccent,
                width: 2,
              ),
              color: value ? goldAccent : Colors.transparent,
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final l10n = AppLocalizations.of(context);
    final bool canProceed = _termsChecked && _privacyChecked && _ageChecked && !_isAccepting;

    return GlassButton(
      text: l10n.acceptAndContinue,
      onPressed: canProceed ? _onAcceptAndContinue : null,
      isLoading: _isAccepting,
    );
  }

  Future<void> _onAcceptAndContinue() async {
    // Prevent double navigation
    if (_isNavigating) return;

    final l10n = AppLocalizations.of(context);

    if (!_termsChecked || !_privacyChecked || !_ageChecked) {
      _showSnackBar(l10n.pleaseAcceptAllRequired);
      return;
    }

    setState(() {
      _isAccepting = true;
      _isNavigating = true;
    });

    try {
      final prefsService = await PreferencesService.getInstance();
      final success = await prefsService.saveLegalAgreementAcceptance(true);

      if (success && mounted) {
        // Check if onboarding is also needed
        final hasCompletedOnboarding = prefsService.hasCompletedOnboarding();

        if (!hasCompletedOnboarding) {
          // Go to onboarding next
          debugPrint('📱 [LegalAgreements] Legal accepted, navigating to onboarding');
          Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        } else {
          // Rare case: legal reset but onboarding done - go home
          debugPrint('🏠 [LegalAgreements] Legal accepted, onboarding already complete, going to home');
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        _showSnackBar(l10n.failedToSaveAcceptance);
        setState(() {
          _isAccepting = false;
          _isNavigating = false;
        });
      }
    } catch (e) {
      _showSnackBar(l10n.genericError(e.toString()));
      setState(() {
        _isAccepting = false;
        _isNavigating = false;
      });
    }
  }

  Future<void> _launchURL(String route) async {
    // Show legal documents using reusable viewer component
    if (route == '/terms') {
      await LegalDocumentViewer.showTermsOfService(context);
    } else if (route == '/privacy') {
      await LegalDocumentViewer.showPrivacyPolicy(context);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    // Determine icon and border color based on message content
    IconData icon;
    Color borderColor;
    Color iconColor;

    if (message.startsWith('Error:') ||
        message.startsWith('Failed') ||
        message.startsWith('Unable')) {
      icon = Icons.error_outline;
      borderColor = Colors.red.withValues(alpha: 0.5);
      iconColor = Colors.red.shade300;
    } else if (message.startsWith('Please')) {
      icon = Icons.info_outline;
      borderColor = Colors.orange.withValues(alpha: 0.5);
      iconColor = Colors.orange.shade300;
    } else {
      icon = Icons.check_circle;
      borderColor = AppTheme.goldColor.withValues(alpha: 0.3);
      iconColor = AppTheme.goldColor;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B), // slate-800
                Color(0xFF0F172A), // slate-900
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
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

  /// Call 988 Suicide & Crisis Lifeline
  Future<void> _call988() async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('tel:988');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar(l10n.unableToCall988);
      }
    } catch (e) {
      _showSnackBar(l10n.genericError(e.toString()));
    }
  }

  /// Text Crisis Text Line
  Future<void> _textCrisisLine() async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('sms:741741?body=HOME');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar(l10n.unableToTextCrisisLine);
      }
    } catch (e) {
      _showSnackBar(l10n.genericError(e.toString()));
    }
  }

  /// Call 911 Emergency Services
  Future<void> _call911() async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('tel:911');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar(l10n.unableToCall911);
      }
    } catch (e) {
      _showSnackBar(l10n.genericError(e.toString()));
    }
  }
}
