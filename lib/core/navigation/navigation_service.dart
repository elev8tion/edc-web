import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../utils/blur_dialog_utils.dart';
import '../../components/base_bottom_sheet.dart';
import '../../features/auth/services/auth_service.dart';

/// Mixin for route protection with authentication checks
mixin RouteGuard {
  /// Check if route requires authentication
  bool shouldGuard(String routeName) {
    return AppRoutes.isAuthRequired(routeName);
  }

  /// Validate access to protected route
  Future<bool> canActivate(BuildContext context, String routeName) async {
    if (!shouldGuard(routeName)) return true;

    try {
      final container = ProviderScope.containerOf(context);
      final isAuthenticated = container.read(isAuthenticatedProvider);

      if (!isAuthenticated) {
        // Store intended destination for post-login redirect
        NavigationService._intendedRoute = routeName;
        debugPrint('[RouteGuard] Access denied to $routeName - not authenticated');
        return false;
      }

      debugPrint('[RouteGuard] Access granted to $routeName');
      return true;
    } catch (e) {
      debugPrint('[RouteGuard] Error checking auth: $e');
      return false;
    }
  }
}

class NavigationService with RouteGuard {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static BuildContext? get context => navigator?.context;

  // ============================================================================
  // Intended route storage for post-auth navigation
  // ============================================================================

  /// Stores the route the user was trying to access before being redirected to auth
  static String? _intendedRoute;

  /// Set the intended route (call before redirecting to auth)
  static void setIntendedRoute(String route) {
    _intendedRoute = route;
  }

  /// Consume and return the intended route (returns null if none set)
  /// This clears the stored route after returning it
  static String? consumeIntendedRoute() {
    final route = _intendedRoute;
    _intendedRoute = null;
    return route;
  }

  /// Check if there's a pending intended route
  static bool get hasIntendedRoute => _intendedRoute != null;

  // ============================================================================
  // Debounce protection to prevent double-tap navigation issues
  // ============================================================================

  static bool _isNavigating = false;
  static bool _isShowingDialog = false;
  static bool _isShowingBottomSheet = false;

  /// Debounce duration to prevent rapid repeated actions
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// Execute an action with debounce protection
  static Future<T?> _withDebounce<T>({
    required bool Function() isActive,
    required void Function(bool) setActive,
    required Future<T?> Function() action,
  }) async {
    print('🔒 [NavService] _withDebounce called, isActive: ${isActive()}');
    if (isActive()) {
      print('❌ [NavService] BLOCKED by debounce! Returning null.');
      return null;
    }

    print('✅ [NavService] Debounce check passed, proceeding...');
    setActive(true);
    print('🔒 [NavService] Set navigation flag to true');

    // Schedule reset before executing action to ensure it always happens
    Future.delayed(_debounceDuration, () {
      setActive(false);
      print('🔒 [NavService] Navigation flag reset to false');
    });

    try {
      print('🔒 [NavService] Executing navigation action...');
      final result = await action();
      print('🔒 [NavService] Navigation action completed with result: $result');
      return result;
    } catch (e) {
      print('❌ [NavService] Navigation action failed: $e');
      rethrow;
    }
  }

  /// Navigate to a route and remove all previous routes
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _withDebounce(
      isActive: () => _isNavigating,
      setActive: (v) => _isNavigating = v,
      action: () => navigator!.pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      ),
    );
  }

  /// Navigate to a route and remove all previous routes WITHOUT debounce protection
  /// Use this for critical one-time navigations like onboarding completion
  static Future<T?> pushAndRemoveUntilImmediate<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    print('🚀 [NavService] IMMEDIATE navigation (bypassing debounce)');
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate to a route WITHOUT debounce protection
  /// Use this for home screen quick actions where rapid navigation to different routes is expected
  static Future<T?> pushNamedImmediate<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    print('🚀 [NavService] IMMEDIATE pushNamed (bypassing debounce)');
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a route (with debounce protection)
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _withDebounce(
      isActive: () => _isNavigating,
      setActive: (v) => _isNavigating = v,
      action: () => navigator!.pushNamed(routeName, arguments: arguments),
    );
  }

  /// Replace current route (with debounce protection)
  static Future<T?> pushReplacementNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _withDebounce(
      isActive: () => _isNavigating,
      setActive: (v) => _isNavigating = v,
      action: () => navigator!.pushReplacementNamed(routeName, arguments: arguments),
    );
  }

  /// Go back
  static void pop<T extends Object?>([T? result]) {
    return navigator!.pop(result);
  }

  /// Check if can go back
  static bool canPop() {
    return navigator!.canPop();
  }

  /// Navigate to home and clear stack
  static Future<void> goToHome() {
    return pushAndRemoveUntil(AppRoutes.home);
  }

  /// Navigate to auth and clear stack
  static Future<void> goToAuth() {
    return pushAndRemoveUntil(AppRoutes.auth);
  }

  /// Navigate to splash
  static Future<void> goToSplash() {
    return pushAndRemoveUntil(AppRoutes.splash);
  }

  // ============================================================================
  // Convenience navigation methods for common routes
  // ============================================================================

  /// Navigate to chat screen
  static Future<void> goToChat() {
    return pushNamed(AppRoutes.chat);
  }

  /// Navigate to devotional screen
  static Future<void> goToDevotional() {
    return pushNamed(AppRoutes.devotional);
  }

  /// Navigate to prayer journal screen
  static Future<void> goToPrayerJournal() {
    return pushNamed(AppRoutes.prayerJournal);
  }

  /// Navigate to verse library screen
  static Future<void> goToVerseLibrary() {
    return pushNamed(AppRoutes.verseLibrary);
  }

  /// Navigate to settings screen
  static Future<void> goToSettings() {
    return pushNamed(AppRoutes.settings);
  }

  /// Navigate to profile screen
  static Future<void> goToProfile() {
    return pushNamed(AppRoutes.profile);
  }

  /// Navigate to reading plan screen
  static Future<void> goToReadingPlan() {
    return pushNamed(AppRoutes.readingPlan);
  }

  /// Navigate to Bible browser screen
  static Future<void> goToBibleBrowser() {
    return pushNamed(AppRoutes.bibleBrowser);
  }

  /// Navigate to accessibility statement screen
  static Future<void> goToAccessibilityStatement() {
    return pushNamed(AppRoutes.accessibilityStatement);
  }

  /// Navigate to chapter reading screen with arguments
  /// Arguments should be a Map with: book, startChapter, endChapter, readingId (optional)
  static Future<void> goToChapterReading({
    required String book,
    required int startChapter,
    required int endChapter,
    String? readingId,
  }) {
    return pushNamed(
      AppRoutes.chapterReading,
      arguments: {
        'book': book,
        'startChapter': startChapter,
        'endChapter': endChapter,
        'readingId': readingId,
      },
    );
  }

  /// Show a dialog (with debounce protection)
  static Future<T?> showAppDialog<T>({
    required Widget dialog,
    bool barrierDismissible = true,
  }) {
    return _withDebounce(
      isActive: () => _isShowingDialog,
      setActive: (v) => _isShowingDialog = v,
      action: () => showBlurredDialog<T>(
        context: context!,
        barrierDismissible: barrierDismissible,
        builder: (_) => dialog,
      ),
    );
  }

  /// Show bottom sheet with dark gradient styling (with debounce protection)
  static Future<T?> showBottomSheet<T>({
    required Widget content,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showHandle = true,
  }) {
    return _withDebounce(
      isActive: () => _isShowingBottomSheet,
      setActive: (v) => _isShowingBottomSheet = v,
      action: () => showCustomBottomSheet<T>(
        context: context!,
        child: content,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        showHandle: showHandle,
      ),
    );
  }

  /// Reset all debounce flags (call when app resumes or in error recovery)
  static void resetDebounceFlags() {
    _isNavigating = false;
    _isShowingDialog = false;
    _isShowingBottomSheet = false;
  }

  // ============================================================================
  // Secure Navigation Methods (with route guard checks)
  // ============================================================================

  /// Navigate with guard check - verifies authentication before navigation
  /// If not authenticated, redirects to auth screen and stores intended route
  Future<void> navigateTo(BuildContext context, String routeName, {Object? arguments}) async {
    if (await canActivate(context, routeName)) {
      navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.auth,
        (route) => false,
      );
    }
  }

  /// Replace current route with guard check
  /// If not authenticated, redirects to auth screen and stores intended route
  Future<void> replaceTo(BuildContext context, String routeName, {Object? arguments}) async {
    if (await canActivate(context, routeName)) {
      navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
    } else {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.auth,
        (route) => false,
      );
    }
  }

  /// Navigate and clear stack (no guard check - use for auth transitions)
  void navigateAndClear(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }
}