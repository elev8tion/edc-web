import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/gradient_background.dart';
import '../components/frosted_glass_card.dart';
import '../components/glassmorphic_fab_menu.dart';
import '../components/glass_button.dart';
import '../components/achievement_badge.dart';
import '../theme/app_theme.dart';
import '../core/navigation/navigation_service.dart';
import '../core/navigation/app_routes.dart';
import '../core/providers/app_providers.dart';
import '../core/services/preferences_service.dart';
import '../core/services/achievement_service.dart';
import '../core/widgets/app_snackbar.dart';
import '../utils/responsive_utils.dart';
import '../utils/blur_dialog_utils.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // User data controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: "friend@example.com");
  String userName = '';
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Invalidate providers on screen load to fetch fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(profileStatsProvider);
      ref.invalidate(totalSharesCountProvider);
      ref.invalidate(discipleCompletionCountProvider);
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await PreferencesService.getInstance();
    final name = prefs.getFirstNameOrDefault();
    setState(() {
      // If it's the default 'friend', treat as empty
      userName = name == 'friend' ? '' : name;
      _nameController.text = userName;
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await PreferencesService.getInstance();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await prefs.saveFirstName(name);
      setState(() {
        userName = name;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.show(
          context,
          message: l10n.profileUpdated,
        );
      }
    } else {
      // If name is empty, delete it from SharedPreferences
      await prefs.deleteFirstName();
      setState(() {
        userName = '';
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.show(
          context,
          message: l10n.nameDeleted,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Build achievements list based on real stats
  List<Achievement> _buildAchievements(
      BuildContext context,
      int prayerStreak,
      int savedVerses,
      int devotionalsCompleted,
      int readingPlansActive,
      int devotionalStreak,
      int totalPrayers,
      int sharedChats,
      int discipleCompletionCount) {
    final l10n = AppLocalizations.of(context);
    return [
      Achievement(
        title: l10n.achievementUnbroken,
        description: l10n.achievementUnbrokenDesc,
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isUnlocked: prayerStreak >= 7,
        progress: prayerStreak >= 7
            ? (prayerStreak % 7 == 0 ? 0 : prayerStreak % 7)
            : prayerStreak,
        total: 7,
        completionCount: prayerStreak >= 7 ? (prayerStreak ~/ 7) : null,
      ),
      Achievement(
        title: l10n.achievementRelentless,
        description: l10n.achievementRelentlessDesc,
        icon: Icons.favorite,
        color: Colors.pink,
        isUnlocked: totalPrayers >= 50,
        progress: totalPrayers >= 50
            ? (totalPrayers % 50 == 0 ? 0 : totalPrayers % 50)
            : totalPrayers,
        total: 50,
        completionCount: totalPrayers >= 50 ? (totalPrayers ~/ 50) : null,
      ),
      Achievement(
        title: l10n.achievementCurator,
        description: l10n.achievementCuratorDesc,
        icon: Icons.book,
        color: Colors.blue,
        isUnlocked: savedVerses >= 100,
        progress: savedVerses >= 100
            ? (savedVerses % 100 == 0 ? 0 : savedVerses % 100)
            : savedVerses,
        total: 100,
        completionCount: savedVerses >= 100 ? (savedVerses ~/ 100) : null,
      ),
      Achievement(
        title: l10n.achievementDailyBread,
        description: l10n.achievementDailyBreadDesc +
            (devotionalStreak > 0
                ? ' • 🔥 $devotionalStreak day${devotionalStreak > 1 ? 's' : ''} streak'
                : ''),
        icon: Icons.auto_stories,
        color: Colors.purple,
        isUnlocked: devotionalsCompleted >= 30,
        progress: devotionalsCompleted >= 30
            ? (devotionalsCompleted % 30 == 0 ? 0 : devotionalsCompleted % 30)
            : devotionalsCompleted,
        total: 30,
        completionCount:
            devotionalsCompleted >= 30 ? (devotionalsCompleted ~/ 30) : null,
      ),
      Achievement(
        title: l10n.achievementDeepDiver,
        description: l10n.achievementDeepDiverDesc,
        icon: Icons.stars,
        color: AppTheme.goldColor,
        isUnlocked: readingPlansActive >= 5,
        progress: readingPlansActive >= 5
            ? (readingPlansActive % 5 == 0 ? 0 : readingPlansActive % 5)
            : readingPlansActive,
        total: 5,
        completionCount:
            readingPlansActive >= 5 ? (readingPlansActive ~/ 5) : null,
      ),
      Achievement(
        title: l10n.achievementDisciple,
        description: l10n.achievementDiscipleDesc,
        icon: Icons.share,
        color: Colors.teal,
        isUnlocked: sharedChats >= 10,
        progress: sharedChats >= 10
            ? (sharedChats % 10 == 0 ? 0 : sharedChats % 10)
            : sharedChats,
        total: 10,
        completionCount: sharedChats >= 10 ? (sharedChats ~/ 10) : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // OPTIMIZED: Watch unified stats provider (1 call instead of 7)
    final stats = ref.watch(profileStatsProvider);

    return stats.when(
      loading: () => const Scaffold(
        body: Stack(
          children: [
            GradientBackground(),
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text(l10n.errorLoadingProfile(error.toString()))),
      ),
      data: (profileStats) => Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              const GradientBackground(),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: ResponsiveUtils.maxContentWidth(context),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top:
                                  80, // Account for pinned header height (70px) + spacing
                              bottom: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.xl),
                                _buildAchievementsSection(
                                  prayerStreak: profileStats.prayerStreak,
                                  savedVerses: profileStats.savedVerses,
                                  devotionalsCompleted:
                                      profileStats.devotionalsCompleted,
                                  readingPlansActive:
                                      profileStats.readingPlansActive,
                                  devotionalStreak:
                                      profileStats.devotionalStreak,
                                  totalPrayers: profileStats.totalPrayers,
                                  sharedChats: profileStats.sharedChats,
                                  discipleCompletionCount:
                                      profileStats.discipleCompletionCount,
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                _buildMenuSection(),
                                const SizedBox(height: AppSpacing.xxl),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasCustomName = userName.isNotEmpty;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _ProfileHeaderDelegate(
        height: 80.0,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.xl, // Top spacing from safe area
          ),
          child: Row(
            children: [
              const SizedBox(width: 56 + AppSpacing.lg), // Space for FAB + gap
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Show pencil icon if no custom name, otherwise show username card
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: AnimatedSwitcher(
                          duration: AppAnimations.normal,
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale:
                                    Tween<double>(begin: 0.8, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: hasCustomName
                              ? FrostedGlassCard(
                                  key: const ValueKey('username_card'),
                                  borderRadius: 20,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.fontSize(
                                          context, 16,
                                          minSize: 14, maxSize: 18),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('pencil_icon'),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldColor
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.goldColor
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: ResponsiveUtils.iconSize(context, 20),
                                    color: AppColors.primaryText,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build achievement badges (all 6, colored if earned, grayed if not)
  Widget _buildEarnedBadges() {
    // Get achievement service
    final achievementService = ref.watch(achievementServiceProvider);

    return FutureBuilder<List<AchievementBadgeData>>(
      future: _getEarnedBadges(achievementService),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return AchievementBadgeRow(badges: snapshot.data!);
      },
    );
  }

  /// Fetch all achievements and their completion counts from AchievementService
  /// Shows ALL badges (colored if earned, grayed out if not)
  /// Optimized: Fetches all counts in parallel for better performance
  Future<List<AchievementBadgeData>> _getEarnedBadges(
      AchievementService service) async {
    final l10n = AppLocalizations.of(context);
    // Fetch all counts in parallel instead of sequentially
    final results = await Future.wait([
      service.getCompletionCount(AchievementType.unbroken),
      service.getCompletionCount(AchievementType.relentless),
      service.getCompletionCount(AchievementType.curator),
      service.getCompletionCount(AchievementType.dailyBread),
      service.getCompletionCount(AchievementType.deepDiver),
      service.getCompletionCount(AchievementType.disciple),
    ]);

    final unbrokenCount = results[0];
    final relentlessCount = results[1];
    final curatorCount = results[2];
    final dailyBreadCount = results[3];
    final deepDiverCount = results[4];
    final discipleCount = results[5];

    return [
      AchievementBadgeData(
        icon: Icons.local_fire_department,
        color: unbrokenCount > 0
            ? Colors.orange
            : Colors.white.withValues(alpha: 0.3),
        completionCount: unbrokenCount,
        title: l10n.achievementUnbroken,
      ),
      AchievementBadgeData(
        icon: Icons.favorite,
        color: relentlessCount > 0
            ? Colors.pink
            : Colors.white.withValues(alpha: 0.3),
        completionCount: relentlessCount,
        title: l10n.achievementRelentless,
      ),
      AchievementBadgeData(
        icon: Icons.book,
        color: curatorCount > 0
            ? Colors.blue
            : Colors.white.withValues(alpha: 0.3),
        completionCount: curatorCount,
        title: l10n.achievementCurator,
      ),
      AchievementBadgeData(
        icon: Icons.auto_stories,
        color: dailyBreadCount > 0
            ? Colors.purple
            : Colors.white.withValues(alpha: 0.3),
        completionCount: dailyBreadCount,
        title: l10n.achievementDailyBread,
      ),
      AchievementBadgeData(
        icon: Icons.stars,
        color: deepDiverCount > 0
            ? AppTheme.goldColor
            : Colors.white.withValues(alpha: 0.3),
        completionCount: deepDiverCount,
        title: l10n.achievementDeepDiver,
      ),
      AchievementBadgeData(
        icon: Icons.share,
        color: discipleCount > 0
            ? Colors.teal
            : Colors.white.withValues(alpha: 0.3),
        completionCount: discipleCount,
        title: l10n.achievementDisciple,
      ),
    ];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs + 2),
        ),
      ),
    );
  }

  Future<void> _launchSupportEmail() async {
    final l10n = AppLocalizations.of(context);
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'connect@everydaychristian.app',
      query: 'subject=Help & Support',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          _showSnackBar(l10n.couldNotOpenEmailApp);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.errorOpeningEmailWithError(e.toString()));
      }
    }
  }

  Widget _buildAchievementsSection({
    required int prayerStreak,
    required int savedVerses,
    required int devotionalsCompleted,
    required int readingPlansActive,
    required int devotionalStreak,
    required int totalPrayers,
    required int sharedChats,
    required int discipleCompletionCount,
  }) {
    final l10n = AppLocalizations.of(context);
    // Build achievements list with real data
    final achievements = _buildAchievements(
      context,
      prayerStreak,
      savedVerses,
      devotionalsCompleted,
      readingPlansActive,
      devotionalStreak,
      totalPrayers,
      sharedChats,
      discipleCompletionCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.achievements,
          style: TextStyle(
            fontSize:
                ResponsiveUtils.fontSize(context, 18, minSize: 16, maxSize: 20),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ).animate().fadeIn(duration: AppAnimations.slow, delay: 200.ms),

        const SizedBox(height: 12),

        // Earned achievement badges (directly under title)
        _buildEarnedBadges()
            .animate()
            .fadeIn(duration: AppAnimations.slow, delay: 250.ms),

        const SizedBox(height: AppSpacing.lg),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildAchievementCard(achievement, index)
                .animate()
                .fadeIn(
                    duration: AppAnimations.slow, delay: (300 + index * 50).ms)
                .slideX(begin: 0.2);
          },
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          // Icon with glow effect for unlocked achievements
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? achievement.color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: AppRadius.mediumRadius,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: achievement.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              achievement.icon,
              size: ResponsiveUtils.iconSize(context, 24),
              color: achievement.isUnlocked
                  ? achievement.color
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 16,
                              minSize: 14, maxSize: 18),
                          fontWeight: FontWeight.w700,
                          color: achievement.isUnlocked
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    if (achievement.isUnlocked)
                      Icon(
                        Icons.check_circle,
                        size: ResponsiveUtils.iconSize(context, 20),
                        color: achievement.color,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 12,
                        minSize: 10, maxSize: 14),
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                // Show progress bar for both unlocked and not-yet-unlocked achievements
                // This allows tracking progress toward next badge level
                if (achievement.progress != null &&
                    achievement.total != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs / 2),
                    child: LinearProgressIndicator(
                      value: achievement.progress! / achievement.total!,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(achievement.color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${achievement.progress}/${achievement.total}',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 10,
                                  minSize: 9, maxSize: 12),
                              color: AppColors.tertiaryText,
                            ),
                          ),
                        ),
                      ),
                      // Show which level we're working toward if already unlocked
                      if (achievement.completionCount != null &&
                          achievement.completionCount! > 0)
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Level ${achievement.completionCount! + 1}',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.fontSize(context, 10,
                                    minSize: 9, maxSize: 12),
                                color: achievement.color.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Add subtle pulse animation for unlocked achievements
    if (achievement.isUnlocked) {
      return card.animate(onPlay: (controller) => controller.repeat()).shimmer(
            duration: const Duration(milliseconds: 2000),
            color: achievement.color.withValues(alpha: 0.3),
            angle: 0,
          );
    }

    return card;
  }

  Widget _buildMenuSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.account,
          style: TextStyle(
            fontSize:
                ResponsiveUtils.fontSize(context, 18, minSize: 16, maxSize: 20),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
          ),
        ).animate().fadeIn(duration: AppAnimations.slow, delay: 400.ms),
        const SizedBox(height: AppSpacing.lg),
        FrostedGlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              _buildMenuItem(
                l10n.settings,
                Icons.settings,
                () async {
                  if (_isNavigating) return;
                  _isNavigating = true;
                  await NavigationService.pushNamedImmediate(
                      AppRoutes.settings);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _isNavigating = false);
                  });
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                l10n.privacyPolicy,
                Icons.privacy_tip,
                _showPrivacyPolicy,
              ),
              _buildDivider(),
              _buildMenuItem(
                l10n.termsOfService,
                Icons.description,
                _showTermsOfService,
              ),
              _buildDivider(),
              _buildMenuItem(
                l10n.helpSupport,
                Icons.help,
                _launchSupportEmail,
              ),
              _buildDivider(),
              _buildMenuItem(
                l10n.signOut,
                Icons.logout,
                _showSignOutDialog,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white.withValues(alpha: 0.9),
        size: ResponsiveUtils.iconSize(context, 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize:
              ResponsiveUtils.fontSize(context, 15, minSize: 13, maxSize: 17),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive
            ? Colors.red.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        size: ResponsiveUtils.iconSize(context, 20),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  void _showEditProfileDialog() {
    final l10n = AppLocalizations.of(context);
    showBlurredDialog(
      context: context,
      builder: (context) {
        // Check if user has a saved name when dialog opens
        final bool hasExistingName = userName.isNotEmpty;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: FrostedGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editProfile,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 20,
                        minSize: 18, maxSize: 24),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.name,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.fontSize(context, 14,
                        minSize: 12, maxSize: 16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.enterYourName,
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mediumRadius,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
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
                        text: hasExistingName ? l10n.delete : l10n.save,
                        height: 48,
                        borderColor: hasExistingName
                            ? Colors.red.withValues(alpha: 0.8)
                            : null,
                        onPressed: () async {
                          // If deleting, clear the text field first
                          if (hasExistingName) {
                            _nameController.clear();
                          }
                          await _saveUserData();
                          NavigationService.pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    final l10n = AppLocalizations.of(context);
    showBlurredDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: FrostedGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: ResponsiveUtils.iconSize(context, 48),
                color: Colors.red,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.signOutQuestion,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 20,
                      minSize: 18, maxSize: 24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.signOutConfirmation,
                style: TextStyle(
                  fontSize: ResponsiveUtils.fontSize(context, 14,
                      minSize: 12, maxSize: 16),
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
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
                      text: l10n.signOut,
                      height: 48,
                      onPressed: () {
                        // In production, handle sign out logic
                        NavigationService.pop();
                        NavigationService.pop(); // Go back to home
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
}

class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int? progress;
  final int? total;
  final int?
      completionCount; // How many times achievement earned (for multiplier display)

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.progress,
    this.total,
    this.completionCount,
  });
}

/// Persistent header delegate for profile username that sticks to the top
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _ProfileHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
