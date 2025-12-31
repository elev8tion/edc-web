import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;
import '../components/gradient_background.dart';
import '../components/glass_button.dart';
import '../components/glass_card.dart';
import '../components/dark_glass_container.dart';
import '../components/pwa_install_dialog.dart';
import '../core/services/preferences_service.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme_extensions.dart';

/// Unified interactive onboarding screen combini1ng legal agreements and feature tour
class UnifiedInteractiveOnboardingScreen extends StatefulWidget {
  const UnifiedInteractiveOnboardingScreen({super.key});

  @override
  State<UnifiedInteractiveOnboardingScreen> createState() =>
      _UnifiedInteractiveOnboardingScreenState();
}

class _UnifiedInteractiveOnboardingScreenState
    extends State<UnifiedInteractiveOnboardingScreen> {
  final GlobalKey _backgroundKey = GlobalKey();
  final UIAudio _audio = UIAudio();

  // Legal agreements
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _ageChecked = false;

  // Navigation state
  bool _isNavigating = false;

  bool get _canProceed => _termsChecked && _privacyChecked && _ageChecked;

  Future<void> _completeOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final prefsService = await PreferencesService.getInstance();

    // Save legal agreements
    await prefsService.saveLegalAgreementAcceptance(true);

    // Mark onboarding as completed
    await prefsService.setOnboardingCompleted();

    // Show PWA install prompt on web (after user is fully authenticated)
    // This ensures cookies/session are copied when user installs
    if (kIsWeb && mounted) {
      await _showPWAInstallPrompt();
    }

    // Navigate to home using IMMEDIATE navigation (bypasses debounce)
    if (mounted) {
      await NavigationService.pushAndRemoveUntilImmediate(AppRoutes.home);
    }
  }

  /// Show PWA install prompt if available
  Future<void> _showPWAInstallPrompt() async {
    try {
      final isIOS = _detectIOS();
      await showPWAInstallDialog(context, isIOS: isIOS);
    } catch (e) {
      debugPrint('[PWA Install] Error showing dialog: $e');
    }
  }

  /// Detect iOS for manual install instructions
  bool _detectIOS() {
    try {
      final userAgent = web.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            key: _backgroundKey,
            child: const GradientBackground(),
          ),
          SafeArea(
            child: _buildLegalPage(l10n),
          ),
        ],
      ),
    );
  }

  // PAGE 1: Legal Agreements
  Widget _buildLegalPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Logo with FAB menu style
          RepaintBoundary(
            child: GlassContainer(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(12.0),
              borderRadius: 30,
              blurStrength: 15.0,
              gradientColors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
              border: Border.all(
                color: AppTheme.goldColor,
                width: 1.5,
              ),
              child: Center(
                child: Image.asset(
                  l10n.localeName == 'es'
                      ? 'assets/images/logo_spanish.png'
                      : 'assets/images/logo_cropped.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.church,
                      color: Colors.white,
                      size: 80,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            l10n.beforeWeBeginReview,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Legal checkboxes
          _buildCheckboxRow(
            value: _termsChecked,
            onChanged: (value) {
              setState(() => _termsChecked = value ?? false);
              HapticFeedback.selectionClick();
              _audio.playTick();
            },
            label: l10n.acceptTermsOfService,
            onViewTapped: () => _openLegalDoc('terms'),
          ),
          const SizedBox(height: 12),
          Container(
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
          const SizedBox(height: 12),
          _buildCheckboxRow(
            value: _privacyChecked,
            onChanged: (value) {
              setState(() => _privacyChecked = value ?? false);
              HapticFeedback.selectionClick();
              _audio.playTick();
            },
            label: l10n.acceptPrivacyPolicy,
            onViewTapped: () => _openLegalDoc('privacy'),
          ),
          const SizedBox(height: 12),
          Container(
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
          const SizedBox(height: 12),
          _buildCheckboxRow(
            value: _ageChecked,
            onChanged: (value) {
              setState(() => _ageChecked = value ?? false);
              HapticFeedback.selectionClick();
              _audio.playTick();
            },
            label: l10n.confirmAge13Plus,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Crisis resources (collapsible)
          DarkGlassContainer(
            child: ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.health_and_safety,
                      color: AppTheme.goldColor, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.crisisResources,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              iconColor: AppColors.primaryText,
              collapsedIconColor: AppColors.secondaryText,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.crisisResourcesText,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Complete onboarding button
          GlassButton(
            text: l10n.beginYourJourney,
            onPressed: _canProceed ? _completeOnboarding : null,
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required String label,
    VoidCallback? onViewTapped,
  }) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimatedCheckbox(
          value: value,
          onTap: () => onChanged?.call(!value),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 15,
                  ),
                ),
              ),
              if (onViewTapped != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onViewTapped,
                  child: Text(
                    l10n.view,
                    style: const TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openLegalDoc(String type) async {
    final url = type == 'terms'
        ? 'https://everydaychristian.app/terms'
        : 'https://everydaychristian.app/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}

/// Animated checkbox with spring physics for playful interaction
class _AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final VoidCallback onTap;

  const _AnimatedCheckbox({
    required this.value,
    required this.onTap,
  });

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0), // Driven by spring physics
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Spring pop animation
    _scaleController
        .animateWith(
      SpringSimulation(
        MotionCharacter.playful,
        _scaleController.value,
        1.1,
        0,
      ),
    )
        .then((_) {
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

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        // Expand hit area to 48x48 for better accessibility
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    widget.value ? AppTheme.goldColor : AppColors.primaryBorder,
                width: 2,
              ),
              color: widget.value ? AppTheme.goldColor : Colors.transparent,
            ),
            child: widget.value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
