import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import '../components/gradient_background.dart';
import '../components/glass_button.dart';
import '../components/glass_card.dart';
import '../components/dark_glass_container.dart';
import '../core/services/preferences_service.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_utils.dart';
import '../utils/motion_character.dart';
import '../utils/ui_audio.dart';
import '../l10n/app_localizations.dart';

/// Unified interactive onboarding screen combini1ng legal agreements and feature tour
class UnifiedInteractiveOnboardingScreen extends StatefulWidget {
  const UnifiedInteractiveOnboardingScreen({super.key});

  @override
  State<UnifiedInteractiveOnboardingScreen> createState() =>
      _UnifiedInteractiveOnboardingScreenState();
}

class _UnifiedInteractiveOnboardingScreenState
    extends State<UnifiedInteractiveOnboardingScreen> {
  final PageController _pageController = PageController();
  final GlobalKey _backgroundKey = GlobalKey();
  final TextEditingController _nameController = TextEditingController();
  final UIAudio _audio = UIAudio();

  // Page 0: Legal agreements
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _ageChecked = false;

  // Page 1: Personalization
  bool _appLockEnabled = false;

  // Navigation state
  bool _isNavigating = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceedFromLegal =>
      _termsChecked && _privacyChecked && _ageChecked;

  Future<void> _toggleAppLock(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final localAuth = LocalAuthentication();

    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.biometricNotAvailable),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      if (enabled) {
        // Verify user can authenticate before enabling
        final authenticated = await localAuth.authenticate(
          localizedReason: l10n.enableAppLockPrompt,
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated) {
          setState(() {
            _appLockEnabled = true;
          });
          HapticFeedback.mediumImpact();
        }
      } else {
        setState(() {
          _appLockEnabled = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      debugPrint('App lock toggle error: $e');
    }
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: AppAnimations.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppAnimations.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    print('🎯 [Onboarding] Button pressed! _isNavigating: $_isNavigating');

    if (_isNavigating) {
      print('❌ [Onboarding] Already navigating, returning early');
      return;
    }
    _isNavigating = true;
    print('🎯 [Onboarding] Set _isNavigating to true');

    print('🎯 [Onboarding] Starting completion process...');

    final prefsService = await PreferencesService.getInstance();

    // Save legal agreements
    await prefsService.saveLegalAgreementAcceptance(true);
    print('🎯 [Onboarding] Legal agreement saved');

    // Save name if provided
    final firstName = _nameController.text.trim();
    if (firstName.isNotEmpty) {
      await prefsService.saveFirstName(firstName);
      print('🎯 [Onboarding] First name saved: $firstName');
    }

    // Save app lock preference
    await prefsService.setAppLockEnabled(_appLockEnabled);
    await prefsService.setBiometricSetupCompleted();
    print('🎯 [Onboarding] App lock preference saved: $_appLockEnabled');

    // Mark onboarding as completed
    await prefsService.setOnboardingCompleted();
    print('🎯 [Onboarding] Onboarding marked complete');

    // Navigate to home using IMMEDIATE navigation (bypasses debounce)
    if (mounted) {
      print(
          '🎯 [Onboarding] Widget is mounted, attempting IMMEDIATE navigation...');
      print(
          '🎯 [Onboarding] Calling NavigationService.pushAndRemoveUntilImmediate...');
      try {
        await NavigationService.pushAndRemoveUntilImmediate(AppRoutes.home);
        print('✅ [Onboarding] Navigation completed successfully!');
      } catch (e) {
        print('❌ [Onboarding] Navigation failed with error: $e');
      }
    } else {
      print('❌ [Onboarding] Widget not mounted, cannot navigate');
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
            child: Column(
              children: [
                // Header with back button (hidden on first page)
                if (_currentPage > 0)
                  Padding(
                    padding: AppSpacing.screenPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: AppColors.primaryText),
                          onPressed: _previousPage,
                        ),
                        const SizedBox(width: 48), // Balance layout
                      ],
                    ),
                  ),

                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildLegalPage(l10n),
                      _buildPersonalizationPage(l10n),
                    ],
                  ),
                ),

                // Page indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: 2,
                    effect: WormEffect(
                      dotColor: AppColors.primaryText.withValues(alpha: 0.3),
                      activeDotColor: AppTheme.goldColor,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 12,
                    ),
                  ),
                ),
              ],
            ),
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

          // Next button
          GlassButton(
            text: l10n.acceptAndContinue,
            onPressed: _canProceedFromLegal ? _nextPage : null,
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
    // Open legal documents (simplified - you can enhance this)
    final url = type == 'terms'
        ? 'https://everydaychristian.app/terms'
        : 'https://everydaychristian.app/privacy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // PAGE 1: Personalization
  Widget _buildPersonalizationPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),

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
                    // Fallback to icon if logo fails to load
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

          const SizedBox(height: AppSpacing.md),

          // Subtitle
          Text(
            l10n.dailyScriptureGuidance,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.goldColor,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            l10n.whatShouldWeCallYou,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Name input (styled like your existing onboarding)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl + 1),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: ResponsiveUtils.fontSize(context, 15,
                    minSize: 13, maxSize: 17),
              ),
              decoration: InputDecoration(
                hintText: l10n.firstNameOptional,
                hintStyle: TextStyle(
                  color: AppColors.tertiaryText,
                  fontSize: ResponsiveUtils.fontSize(context, 15,
                      minSize: 13, maxSize: 17),
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
            ),
          ),

          const SizedBox(height: AppSpacing.xl + AppSpacing.xl + 22),

          // App Lock Toggle
          DarkGlassContainer(
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppTheme.goldColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appLock,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.appLockDesc,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle
                Switch(
                  value: _appLockEnabled,
                  onChanged: _toggleAppLock,
                  activeTrackColor: Colors.white.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.goldColor;
                      }
                      return Colors.white.withValues(alpha: 0.7);
                    },
                  ),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Get started button
          GlassButton(
            text: l10n.beginYourJourney,
            onPressed: _completeOnboarding,
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
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
