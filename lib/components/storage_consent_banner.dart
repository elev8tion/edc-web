import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/storage_consent_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import 'glass_button.dart';

/// Storage Consent Banner for EU ePrivacy Directive compliance
///
/// Features:
/// - Fixed position at bottom of screen
/// - Glassmorphic design matching app aesthetic
/// - Two options: Accept All / Essential Only
/// - Privacy Policy link
/// - Only shows on web platform when consent not given
class StorageConsentBanner extends StatefulWidget {
  final Widget child;

  const StorageConsentBanner({super.key, required this.child});

  @override
  State<StorageConsentBanner> createState() => _StorageConsentBannerState();
}

class _StorageConsentBannerState extends State<StorageConsentBanner>
    with SingleTickerProviderStateMixin {
  bool _showBanner = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _checkConsentStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConsentStatus() async {
    // Only check on web
    if (!kIsWeb) return;

    try {
      final consentService = await StorageConsentService.getInstance();
      final shouldShow = consentService.shouldShowConsentBanner();

      if (shouldShow && mounted) {
        setState(() => _showBanner = true);
        // Slight delay before showing banner for better UX
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('[StorageConsentBanner] Error checking consent: $e');
    }
  }

  Future<void> _handleAcceptAll() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final consentService = await StorageConsentService.getInstance();
      await consentService.acceptAll();

      if (mounted) {
        await _animationController.reverse();
        setState(() {
          _showBanner = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StorageConsentBanner] Error accepting all: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEssentialOnly() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final consentService = await StorageConsentService.getInstance();
      await consentService.acceptEssentialOnly();

      if (mounted) {
        await _animationController.reverse();
        setState(() {
          _showBanner = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StorageConsentBanner] Error accepting essential: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://everydaychristian.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner) _buildBanner(context),
      ],
    );
  }

  Widget _buildBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: bottomPadding + 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.6),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
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
                              Icons.cookie_outlined,
                              color: AppTheme.goldColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.storageConsentTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        l10n.storageConsentMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Privacy Policy Link
                      GestureDetector(
                        onTap: _openPrivacyPolicy,
                        child: Text(
                          l10n.storageConsentLearnMore,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.goldColor,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buttons
                      Row(
                        children: [
                          // Essential Only button
                          Expanded(
                            child: GlassButton(
                              text: l10n.essentialOnly,
                              height: 44,
                              onPressed:
                                  _isLoading ? null : _handleEssentialOnly,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Accept All button (primary)
                          Expanded(
                            child: GlassButton(
                              text: l10n.acceptAllStorage,
                              height: 44,
                              borderColor: AppTheme.goldColor,
                              onPressed: _isLoading ? null : _handleAcceptAll,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
