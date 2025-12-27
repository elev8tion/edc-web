import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_auth/local_auth.dart';
import '../core/services/database_service.dart';
import '../core/services/preferences_service.dart';
import '../core/services/bible_config.dart';
import '../features/auth/services/secure_storage_service.dart';
import '../components/pin_setup_dialog.dart';
import '../services/conversation_service.dart';
import '../theme/app_theme.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../components/standard_screen_header.dart';
import '../core/navigation/navigation_service.dart';
import '../core/providers/app_providers.dart';
import '../utils/responsive_utils.dart';
import '../widgets/time_picker/time_range_sheet.dart';
import '../widgets/time_picker/time_range_sheet_style.dart';
import '../components/glass_button.dart';
import '../components/dark_glass_container.dart';
import '../components/glass_card.dart';
import 'paywall_screen.dart';
import '../utils/blur_dialog_utils.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/app_snackbar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppLockStatus();
  }

  Future<void> _loadAppLockStatus() async {
    final prefs = await PreferencesService.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.isAppLockEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            const GradientBackground(),
            SafeArea(
              child: _buildSettingsContent(),
            ),
            // Pinned FAB
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.xl,
              left: AppSpacing.xl,
              child: const GlassmorphicFABMenu()
                  .animate()
                  .fadeIn(duration: AppAnimations.slow)
                  .slideY(begin: -0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return StandardScreenHeader(
      title: l10n.settings,
      subtitle: l10n.settingsSubtitle,
      showFAB: false, // FAB is positioned separately
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: -0.3);
  }

  Widget _buildSettingsContent() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.notifications,
            Icons.notifications,
            [
              _buildNotificationTile(
                context: context,
                icon: Icons.wb_sunny_outlined,
                title: l10n.dailyDevotional,
                subtitle: l10n.dailyDevotionalNotificationDesc,
                isEnabled: ref.watch(dailyNotificationsProvider),
                currentTime: ref.watch(devotionalTimeProvider),
                onToggle: (value) =>
                    ref.read(dailyNotificationsProvider.notifier).toggle(value),
                onTimeChange: (time) =>
                    ref.read(devotionalTimeProvider.notifier).setTime(time),
              ),
              _buildNotificationTile(
                context: context,
                icon: Icons.favorite_border,
                title: l10n.prayerReminders,
                subtitle: l10n.prayerRemindersNotificationDesc,
                isEnabled: ref.watch(prayerRemindersProvider),
                currentTime: ref.watch(prayerTimeProvider),
                onToggle: (value) =>
                    ref.read(prayerRemindersProvider.notifier).toggle(value),
                onTimeChange: (time) =>
                    ref.read(prayerTimeProvider.notifier).setTime(time),
              ),
              _buildNotificationTile(
                context: context,
                icon: Icons.auto_awesome,
                title: l10n.verseOfTheDaySetting,
                subtitle: l10n.verseOfTheDayNotificationDesc,
                isEnabled: ref.watch(verseOfTheDayProvider),
                currentTime: ref.watch(verseTimeProvider),
                onToggle: (value) =>
                    ref.read(verseOfTheDayProvider.notifier).toggle(value),
                onTimeChange: (time) =>
                    ref.read(verseTimeProvider.notifier).setTime(time),
              ),
              _buildNotificationTile(
                context: context,
                icon: Icons.menu_book_outlined,
                title: l10n.readingPlan,
                subtitle: l10n.readingPlanNotificationDesc,
                isEnabled: ref.watch(readingPlanRemindersProvider),
                currentTime: ref.watch(readingPlanTimeProvider),
                onToggle: (value) => ref
                    .read(readingPlanRemindersProvider.notifier)
                    .toggle(value),
                onTimeChange: (time) =>
                    ref.read(readingPlanTimeProvider.notifier).setTime(time),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.subscription,
            Icons.workspace_premium,
            [
              _buildNavigationTile(
                l10n.manageSubscription,
                _getSubscriptionStatus(ref),
                Icons.arrow_forward_ios,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaywallScreen(
                        showTrialInfo: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.bibleSettings,
            Icons.menu_book,
            [
              _buildInfoTile(
                l10n.bibleVersion,
                BibleConfig.getVersion(
                    Localizations.localeOf(context).languageCode),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.appearance,
            Icons.palette,
            [
              _buildSliderTile(
                l10n.textSize,
                l10n.textSizeDesc,
                ref.watch(textSizeProvider),
                0.8,
                1.5,
                (value) =>
                    ref.read(textSizeProvider.notifier).setTextSize(value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.dataPrivacy,
            Icons.security,
            [
              _buildAppLockTile(),
              _buildPinManagementTile(),
              _buildActionTile(
                l10n.clearCache,
                l10n.clearCacheDesc,
                Icons.delete_outline,
                () => _showClearCacheDialog(),
              ),
              _buildActionTile(
                l10n.exportData,
                l10n.exportDataDesc,
                Icons.download,
                () => _exportUserData(),
              ),
              _buildActionTile(
                l10n.deleteAllData,
                l10n.deleteAllDataDesc,
                Icons.warning_amber_rounded,
                () => _showDeleteAllDataDialog(),
                isDestructive: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.support,
            Icons.help,
            [
              _buildActionTile(
                l10n.helpFAQ,
                l10n.helpFAQDesc,
                Icons.help_outline,
                () => _showHelpDialog(),
              ),
              _buildActionTile(
                l10n.contactSupport,
                l10n.contactSupportDesc,
                Icons.email,
                () => _contactSupport(),
              ),
              _buildActionTile(
                l10n.rateApp,
                l10n.rateAppDesc,
                Icons.star_outline,
                () => _rateApp(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _buildSettingsSection(
            l10n.about,
            Icons.info,
            [
              _buildInfoTile(l10n.versionLabel, l10n.version),
              _buildActionTile(
                l10n.privacyPolicy,
                l10n.privacyPolicyDesc,
                Icons.privacy_tip,
                () => _showPrivacyPolicy(),
              ),
              _buildActionTile(
                l10n.termsOfService,
                l10n.termsOfServiceDesc,
                Icons.description,
                () => _showTermsOfService(),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: AppSpacing.screenPadding,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassContainer(
                borderRadius: AppRadius.xs + 2,
                blurStrength: 15.0,
                gradientColors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
                padding: const EdgeInsets.all(AppSpacing.sm),
                enableNoise: true,
                enableLightSimulation: true,
                border: Border.all(
                  color: AppTheme.goldColor,
                  width: 1.0,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryText,
                  size: ResponsiveUtils.iconSize(context, 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 18,
                        minSize: 16, maxSize: 20),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    shadows: AppTheme.textShadowSubtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: AppAnimations.slow).slideY(begin: 0.3);
  }

  Widget _buildSliderTile(String title, String subtitle, double value,
      double min, double max, Function(double) onChanged) {
    return DarkGlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: AppRadius.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16,
                            minSize: 14, maxSize: 18),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 0.1).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required String currentTime,
    required Function(bool) onToggle,
    required Function(String) onTimeChange,
  }) {
    final l10n = AppLocalizations.of(context);
    // Updated color scheme: amber for icons and toggles, white for time text
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Main notification row with toggle
          Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.toggleActiveColor.withValues(alpha: 0.3),
                      AppTheme.toggleActiveColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.smallRadius,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtils.iconSize(context, 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16,
                            minSize: 14, maxSize: 18),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 13,
                            minSize: 11, maxSize: 15),
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle switch
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeTrackColor: Colors.white.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.secondaryColor;
                    }
                    return AppTheme.secondaryColor;
                  },
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.secondaryColor;
                    }
                    return AppTheme.secondaryColor;
                  },
                ),
              ),
            ],
          ),
          // Time picker (shown when enabled)
          if (isEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTimePicker(currentTime, onTimeChange),
                borderRadius: AppRadius.mediumRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: AppRadius.mediumRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color:
                            AppTheme.toggleActiveColor.withValues(alpha: 0.8),
                        size: ResponsiveUtils.iconSize(context, 18),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.notificationTime,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 14,
                                minSize: 12, maxSize: 16),
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatTimeTo12Hour(currentTime),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 15,
                              minSize: 13, maxSize: 17),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.tertiaryText,
                        size: ResponsiveUtils.iconSize(context, 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppLockTile() {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon with gradient background (matching notification tiles)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.toggleActiveColor.withValues(alpha: 0.3),
                  AppTheme.toggleActiveColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.smallRadius,
            ),
            child: Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: ResponsiveUtils.iconSize(context, 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appLock,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 16,
                        minSize: 14, maxSize: 18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.appLockDesc,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 13,
                        minSize: 11, maxSize: 15),
                    color: AppColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          // Toggle switch (matching notification tiles)
          Switch(
            value: _isAppLockEnabled,
            onChanged: _toggleAppLock,
            activeTrackColor: Colors.white.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.secondaryColor;
                }
                return AppTheme.secondaryColor;
              },
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.secondaryColor;
                }
                return AppTheme.secondaryColor;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAppLock(bool enabled) async {
    final l10n = AppLocalizations.of(context);
    final localAuth = LocalAuthentication();

    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (!mounted) return;
        AppSnackBar.showError(context, message: l10n.biometricNotAvailable);
        return;
      }

      if (enabled) {
        // Verify user can authenticate before enabling
        final authenticated = await localAuth.authenticate(
          localizedReason: l10n.verifyIdentityAppLock,
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated) {
          final prefs = await PreferencesService.getInstance();
          await prefs.setAppLockEnabled(true);
          setState(() {
            _isAppLockEnabled = true;
          });

          if (!mounted) return;
          AppSnackBar.show(
            context,
            message: l10n.appLockEnabled,
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        }
      } else {
        // Disable app lock
        final prefs = await PreferencesService.getInstance();
        await prefs.setAppLockEnabled(false);
        setState(() {
          _isAppLockEnabled = false;
        });

        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: l10n.appLockDisabled,
          icon: Icons.lock_open,
          iconColor: Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('App lock toggle error: $e');
    }
  }

  /// Build PIN management tile (mobile only)
  Widget _buildPinManagementTile() {
    // PIN management not available on web
    if (kIsWeb) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: Future.value(false), // Skip PIN check on web
      builder: (context, snapshot) {
        final hasPin = snapshot.data ?? false;

        return _buildActionTile(
          hasPin ? 'Change App PIN' : 'Set App PIN',
          hasPin
              ? 'Update your app PIN for fallback authentication'
              : 'Create a PIN as backup when biometrics fail',
          Icons.pin,
          hasPin ? _handleChangePIN : _handleSetPIN,
        );
      },
    );
  }

  /// Handle setting new PIN
  Future<void> _handleSetPIN() async {
    final created = await PinSetupDialog.show(context);

    if (created && mounted) {
      AppSnackBar.show(
        context,
        message: 'App PIN created successfully',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      setState(() {}); // Refresh tile
    }
  }

  /// Handle changing existing PIN
  Future<void> _handleChangePIN() async {
    const secureStorage = SecureStorageService();

    // First verify current PIN
    final verified = await _showPINVerificationDialog();
    if (!verified || !mounted) return;

    // Show PIN setup dialog to create new PIN
    final created = await PinSetupDialog.show(context);

    if (created && mounted) {
      AppSnackBar.show(
        context,
        message: 'App PIN updated successfully',
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );
      setState(() {}); // Refresh tile
    }
  }

  /// Show dialog to verify current PIN before changing (mobile only)
  Future<bool> _showPINVerificationDialog() async {
    // PIN verification not available on web
    if (kIsWeb) return false;

    final pinController = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: const Text(
            'Verify Current PIN',
            style: TextStyle(
              color: AppTheme.goldColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your current PIN to continue',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 8,
                  ),
                  errorText: errorText,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppTheme.goldColor,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (pin) async {
                  // PIN verification skipped on web
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // PIN verification skipped on web
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    pinController.dispose();
    return result ?? false;
  }

  String _formatTimeTo12Hour(String time24) {
    final parts = time24.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$hour12:$minuteStr $period';
  }

  Future<void> _showTimePicker(
      String currentTime, Function(String) onChanged) async {
    final l10n = AppLocalizations.of(context);
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    // Get text scale factor to adjust dimensions dynamically for accessibility
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;

    // Custom glassmorphic time picker style matching app theme components
    final customStyle = TimeRangeSheetStyle(
      // Match GlassBottomSheet - transparent background (blur from wrapper)
      sheetBackgroundColor: Colors.transparent,

      // Button styling matching GlassButton component
      buttonColor:
          Colors.transparent, // GlassButton uses gradient, not solid color
      cancelButtonColor: Colors.transparent,
      buttonTextColor: Colors.white,
      cancelButtonTextColor: Colors.white.withValues(alpha: 0.7),

      // Text colors for visibility
      labelTextColor: Colors.white.withValues(alpha: 0.9),
      selectedTimeTextColor: Colors.white,
      pickerTextColor: Colors.white.withValues(alpha: 0.3),
      selectedPickerTextColor: Colors.white,

      // Corner radius matching GlassButton (28) and GlassBottomSheet (24)
      cornerRadius: 24, // Sheet corner radius
      buttonCornerRadius: 28, // Button corner radius like GlassButton

      // Sheet dimensions - dynamically scaled for text size and bottom safe area
      // Increased height to accommodate 1.5x text scale + extra bottom padding
      sheetHeight: 500 +
          (textScaleFactor > 1.0 ? (textScaleFactor - 1.0) * 100 : 0) +
          safeBottomPadding,
      // Scale picker item height with text scale factor for proper spacing at 150%
      pickerItemHeight: (45 * textScaleFactor).clamp(45, 70),
      buttonHeight: 56, // Match GlassButton height

      // Padding and spacing - add substantial bottom padding for scaled text
      // Ensures bottom numbers (07, 08, 09, 10) are fully visible at 150% scale
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom:
            AppSpacing.lg + 50 + safeBottomPadding, // Extra 50px + safe area
      ),
      buttonPadding: const EdgeInsets.all(AppSpacing.md),

      // Use 12-hour format to match display
      use24HourFormat: false,

      // Custom button text
      confirmButtonText: l10n.setTime,
      cancelButtonText: l10n.cancel,

      // Enable haptic feedback
      enableHapticFeedback: true,
    );

    final result = await showTimeRangeSheet(
      context: context,
      initialStartTime: initialTime,
      style: customStyle,
      singlePicker: true,
      allowInvalidRange: true,
    );

    if (result != null) {
      final picked = result.startTime; // In single picker mode, use startTime
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      onChanged('$hour:$minute');
    }
  }

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    const textColor = AppColors.primaryText;
    final subtitleColor = Colors.white.withValues(alpha: 0.7);
    final iconColor = isDestructive ? Colors.red : AppColors.primaryText;
    final borderColor = isDestructive
        ? Colors.red.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mediumRadius,
          child: Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: isDestructive
                  ? LinearGradient(
                      colors: [
                        Colors.red.withValues(alpha: 0.15),
                        Colors.red.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                GlassContainer(
                  borderRadius: AppRadius.xs + 2,
                  blurStrength: 15.0,
                  gradientColors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  enableNoise: true,
                  enableLightSimulation: true,
                  border: Border.all(
                    color: isDestructive ? Colors.red : AppTheme.goldColor,
                    width: 1.0,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: ResponsiveUtils.iconSize(context, 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 16,
                              minSize: 14, maxSize: 18),
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 13,
                              minSize: 11, maxSize: 15),
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDestructive
                      ? Colors.red.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                  size: ResponsiveUtils.iconSize(context, 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 16,
                    minSize: 14, maxSize: 18),
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 15,
                  minSize: 13, maxSize: 17),
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    final l10n = AppLocalizations.of(context);

    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
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
                            AppTheme.primaryColor.withValues(alpha: 0.3),
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                      ),
                      child: Icon(
                        Icons.cleaning_services,
                        color: AppColors.primaryText,
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.clearCacheDialogTitle,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 20,
                              minSize: 18, maxSize: 24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.clearCacheDialogMessage,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 13,
                        minSize: 11, maxSize: 15),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: l10n.cancel,
                        height: 48,
                        onPressed: () => NavigationService.pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GlassButton(
                        text: l10n.clear,
                        height: 48,
                        borderColor: Colors.redAccent,
                        onPressed: () async {
                          NavigationService.pop();
                          await _clearCache();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Clear Flutter image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      // Clear temporary directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }

      // Clear app cache directory (does not delete user data/database)
      try {
        final cacheDir = await getApplicationCacheDirectory();
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create();
        }
      } catch (e) {
        debugPrint('Could not clear cache directory: $e');
      }

      _showSnackBar(l10n.cacheClearedSuccessfully);
    } catch (e) {
      _showSnackBar(l10n.failedToClearCache(e.toString()));
    }
  }

  Future<void> _exportUserData() async {
    final l10n = AppLocalizations.of(context);
    try {
      final buffer = StringBuffer();
      buffer.writeln('=' * 60);
      buffer.writeln('EVERYDAY CHRISTIAN - DATA EXPORT');
      buffer.writeln('Export Date: ${DateTime.now().toString()}');
      buffer.writeln('=' * 60);
      buffer.writeln();

      // Export Prayer Journal
      final prayerService = ref.read(prayerServiceProvider);
      final prayerExport = await prayerService.exportPrayerJournal();

      if (prayerExport.isNotEmpty) {
        buffer.writeln('📿 PRAYER JOURNAL');
        buffer.writeln('=' * 60);
        buffer.writeln(prayerExport);
        buffer.writeln();
      }

      // Export AI Chat Conversations
      final conversationService = ConversationService();
      final sessions =
          await conversationService.getSessions(includeArchived: true);

      if (sessions.isNotEmpty) {
        buffer.writeln('💬 AI CHAT CONVERSATIONS');
        buffer.writeln('=' * 60);
        buffer.writeln('Total Sessions: ${sessions.length}');
        buffer.writeln();

        for (final session in sessions) {
          final sessionId = session['id'] as String;
          final title = session['title'] as String;
          final isArchived = session['is_archived'] == 1;

          final conversationExport =
              await conversationService.exportConversation(sessionId);

          if (conversationExport.isNotEmpty) {
            buffer.writeln('-' * 60);
            buffer.writeln('Session: $title ${isArchived ? "(Archived)" : ""}');
            buffer.writeln('-' * 60);
            buffer.writeln(conversationExport);
            buffer.writeln();
          }
        }
      }

      final exportText = buffer.toString();

      if (exportText.isEmpty || exportText.length < 200) {
        _showSnackBar(l10n.noDataToExport);
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          text: exportText,
          subject: 'Everyday Christian - Data Export',
        ),
      );

      final prayerCount = prayerExport.isNotEmpty ? 1 : 0;
      final chatCount = sessions.length;
      _showSnackBar(l10n.exportedDataSuccessfully(prayerCount, chatCount));
    } catch (e) {
      _showSnackBar(l10n.chatFailedToExport(e.toString()));
    }
  }

  void _showDeleteAllDataDialog() {
    final l10n = AppLocalizations.of(context);
    final confirmController = TextEditingController();

    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.deleteAllData,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 20,
                              minSize: 18, maxSize: 24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '⚠️ THIS ACTION CANNOT BE UNDONE ⚠️',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.thisWillPermanentlyDelete,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 14,
                                minSize: 12, maxSize: 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildDeleteItem('✝️ All prayer journal entries'),
                        _buildDeleteItem('💬 All AI chat conversations'),
                        _buildDeleteItem('📖 Reading plan progress'),
                        _buildDeleteItem('🌟 Favorite verses'),
                        _buildDeleteItem('📝 Devotional completion history'),
                        _buildDeleteItem('⚙️ All app settings and preferences'),
                        _buildDeleteItem('👤 Profile picture'),
                        _buildDeleteItem('📊 All statistics and progress'),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.deleteLocalDataWarning,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(
                                      context, 13,
                                      minSize: 11, maxSize: 15),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.deleteDataBulletList,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(
                                      context, 12,
                                      minSize: 10, maxSize: 14),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                  border: Border.all(
                                      color:
                                          Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l10n.subscriptionWillRestore,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.fontSize(
                                              context, 11,
                                              minSize: 9, maxSize: 13),
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.typeDeleteToConfirm,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.fontSize(context, 13,
                                minSize: 11, maxSize: 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: confirmController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.fontSize(context, 14,
                                minSize: 12, maxSize: 16),
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.typeDeletePlaceholder,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: ResponsiveUtils.fontSize(context, 14,
                                  minSize: 12, maxSize: 16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            contentPadding: const EdgeInsets.all(AppSpacing.md),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: l10n.cancel,
                        height: 48,
                        onPressed: () {
                          confirmController.dispose();
                          NavigationService.pop();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GlassButton(
                        text: l10n.delete,
                        height: 48,
                        borderColor: Colors.red.withValues(alpha: 0.8),
                        onPressed: () async {
                          if (confirmController.text.trim() == 'DELETE') {
                            confirmController.dispose();
                            NavigationService.pop();
                            await _deleteAllData();
                          } else {
                            _showSnackBar(l10n.mustTypeDeleteToConfirm);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: ResponsiveUtils.fontSize(context, 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final l10n = AppLocalizations.of(context);
    try {
      // Show loading indicator
      showBlurredDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: FrostedGlassCard(
            borderColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    l10n.deletingAllData,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.fontSize(context, 14,
                          minSize: 12, maxSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. Reset database (clears all prayer, chat, favorites, reading plans, etc.)
      final dbService = DatabaseService();
      await dbService.resetDatabase();

      // 2. Clear SharedPreferences (all app settings)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Clear all cache
      try {
        imageCache.clear();
        imageCache.clearLiveImages();
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          await tempDir.create();
        }
        final cacheDir = await getApplicationCacheDirectory();
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create();
        }
      } catch (e) {
        debugPrint('Cache clearing failed: $e');
      }

      // Close loading dialog
      if (mounted) {
        NavigationService.pop();
      }

      // Show success message
      _showSnackBar(l10n.allDataDeleted);

      // Wait a moment then exit the app (user needs to restart)
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        // Reset the app state by navigating to home
        NavigationService.goToHome();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        NavigationService.pop();
      }
      _showSnackBar(l10n.failedToDeleteData(e.toString()));
    }
  }

  void _showHelpDialog() {
    final l10n = AppLocalizations.of(context);

    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: ResponsiveUtils.maxContentWidth(context),
          ),
          child: FrostedGlassCard(
            borderColor: AppTheme.goldColor,
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
                            AppTheme.primaryColor.withValues(alpha: 0.3),
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xs + 2),
                      ),
                      child: Icon(
                        Icons.help_outline,
                        color: AppColors.primaryText,
                        size: ResponsiveUtils.iconSize(context, 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.helpFAQ,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 20,
                              minSize: 18, maxSize: 24),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.faqSubtitle,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 13,
                        minSize: 11, maxSize: 15),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Scrollable FAQ List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFAQSection(l10n.faqGettingStarted, [
                          _FAQItem(question: l10n.faqQ1, answer: l10n.faqA1),
                          _FAQItem(question: l10n.faqQ2, answer: l10n.faqA2),
                          _FAQItem(question: l10n.faqQ3, answer: l10n.faqA3),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqBibleReading, [
                          _FAQItem(question: l10n.faqQ4, answer: l10n.faqA4),
                          _FAQItem(question: l10n.faqQ5, answer: l10n.faqA5),
                          _FAQItem(question: l10n.faqQ6, answer: l10n.faqA6),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqPrayerJournal, [
                          _FAQItem(question: l10n.faqQ7, answer: l10n.faqA7),
                          _FAQItem(question: l10n.faqQ8, answer: l10n.faqA8),
                          _FAQItem(question: l10n.faqQ9, answer: l10n.faqA9),
                          _FAQItem(question: l10n.faqQ10, answer: l10n.faqA10),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqDevotionalsPlans, [
                          _FAQItem(question: l10n.faqQ11, answer: l10n.faqA11),
                          _FAQItem(question: l10n.faqQ12, answer: l10n.faqA12),
                          _FAQItem(question: l10n.faqQ13, answer: l10n.faqA13),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqAIChatSupport, [
                          _FAQItem(question: l10n.faqQ14, answer: l10n.faqA14),
                          _FAQItem(question: l10n.faqQ15, answer: l10n.faqA15),
                          _FAQItem(question: l10n.faqQ16, answer: l10n.faqA16),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqNotifications, [
                          _FAQItem(question: l10n.faqQ17, answer: l10n.faqA17),
                          _FAQItem(question: l10n.faqQ18, answer: l10n.faqA18),
                          _FAQItem(question: l10n.faqQ19, answer: l10n.faqA19),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqSettingsCustomization, [
                          _FAQItem(question: l10n.faqQ20, answer: l10n.faqA20),
                          _FAQItem(question: l10n.faqQ21, answer: l10n.faqA21),
                          _FAQItem(question: l10n.faqQ22, answer: l10n.faqA22),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFAQSection(l10n.faqDataPrivacy, [
                          _FAQItem(question: l10n.faqQ23, answer: l10n.faqA23),
                          _FAQItem(question: l10n.faqQ24, answer: l10n.faqA24),
                          _FAQItem(question: l10n.faqQ25, answer: l10n.faqA25),
                          _FAQItem(question: l10n.faqQ26, answer: l10n.faqA26),
                          _FAQItem(question: l10n.faqQ27, answer: l10n.faqA27),
                        ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Close Button
                GlassButton(
                  text: l10n.close,
                  height: 48,
                  onPressed: () => NavigationService.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(String title, List<_FAQItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 16,
                  minSize: 14, maxSize: 18),
              fontWeight: FontWeight.w700,
              color: AppTheme.goldColor,
            ),
          ),
        ),
        ...items.map((item) => _buildFAQTile(item.question, item.answer)),
      ],
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: AppRadius.mediumRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: AppSpacing.cardPadding,
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          title: Text(
            question,
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 14,
                  minSize: 12, maxSize: 16),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            softWrap: true,
            maxLines: null,
          ),
          iconColor: AppColors.primaryText,
          collapsedIconColor: Colors.white.withValues(alpha: 0.5),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 13,
                    minSize: 11, maxSize: 15),
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'connect@everydaychristian.app',
      queryParameters: {
        'subject': 'Everyday Christian Support Request',
        'body': 'Please describe your issue or question:\n\n',
      },
    );

    final l10n = AppLocalizations.of(context);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _showSnackBar(l10n.couldNotOpenEmailClient);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.errorOpeningEmail);
      }
    }
  }

  void _rateApp() {
    final l10n = AppLocalizations.of(context);
    _showSnackBar(l10n.openingAppStore);
  }

  Future<void> _showPrivacyPolicy() async {
    final uri = Uri.parse('https://everydaychristian.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showTermsOfService() async {
    final uri = Uri.parse('https://everydaychristian.app/terms');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnackBar(String message) {
    // Determine icon and border color based on message content
    IconData icon;
    Color borderColor;
    Color iconColor;

    if (message.startsWith('✅') || message.startsWith('✓')) {
      icon = Icons.check_circle;
      borderColor = AppTheme.goldColor.withValues(alpha: 0.3);
      iconColor = AppTheme.goldColor;
    } else if (message.startsWith('❌') || message.startsWith('✗')) {
      icon = Icons.error_outline;
      borderColor = Colors.red.withValues(alpha: 0.5);
      iconColor = Colors.red.shade300;
    } else if (message.startsWith('⚠️')) {
      icon = Icons.warning_amber_outlined;
      borderColor = Colors.orange.withValues(alpha: 0.5);
      iconColor = Colors.orange.shade300;
    } else if (message.startsWith('📤') || message.startsWith('📥')) {
      icon = Icons.upload_outlined;
      borderColor = AppTheme.goldColor.withValues(alpha: 0.3);
      iconColor = AppTheme.goldColor;
    } else {
      icon = Icons.info_outline;
      borderColor = AppTheme.goldColor.withValues(alpha: 0.3);
      iconColor = Colors.white70;
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
              Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.fontSize(context, 14),
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

  /// Get subscription status text
  String _getSubscriptionStatus(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final isInTrial = ref.watch(isInTrialProvider);
    final remainingMessages = ref.watch(remainingMessagesProvider);

    if (isPremium) {
      return l10n.messagesLeftThisMonth(remainingMessages);
    } else if (isInTrial) {
      return l10n.messagesLeftToday(remainingMessages);
    } else {
      return l10n.startYourFreeTrial;
    }
  }

  /// Build navigation tile
  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData trailingIcon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              trailingIcon,
              size: 18,
              color: AppColors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

// FAQ Item Model
class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({
    required this.question,
    required this.answer,
  });
}
