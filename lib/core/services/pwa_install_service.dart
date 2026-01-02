// Conditional import for web
import 'pwa_install_service_stub.dart'
    if (dart.library.html) 'pwa_install_service_web.dart';

/// Service for managing PWA installation
///
/// This service provides a unified interface for PWA installation across
/// platforms. On web, it uses the native beforeinstallprompt API to trigger
/// app installation. On non-web platforms, it provides no-op implementations.
///
/// Features:
/// - Captures and defers the beforeinstallprompt event
/// - Tracks install dismissals to avoid annoying users
/// - Detects iOS for manual install instructions
/// - Detects if app is already installed (standalone mode)
class PwaInstallService {
  static final PwaInstallService _instance = PwaInstallService._internal();
  factory PwaInstallService() => _instance;
  PwaInstallService._internal();

  final PwaInstallServiceImpl _impl = PwaInstallServiceImpl();

  /// Initialize PWA install listener
  ///
  /// Call this early in app lifecycle (e.g., in main.dart) to capture
  /// the beforeinstallprompt event when it fires.
  void initialize() => _impl.initialize();

  /// Check if PWA can be installed
  ///
  /// Returns true if:
  /// - User hasn't dismissed too many times
  /// - beforeinstallprompt event was captured
  /// - App is not already installed
  bool get canPrompt => _impl.canPrompt;

  /// Check if already installed
  ///
  /// Returns true if running in standalone/fullscreen mode
  /// or if previously marked as installed.
  bool get isInstalled => _impl.isInstalled;

  /// Check if on iOS (requires manual install)
  ///
  /// iOS Safari doesn't support beforeinstallprompt, so users
  /// need to manually use the Share menu to add to home screen.
  bool get isIOS => _impl.isIOS;

  /// Trigger install prompt
  ///
  /// Calls prompt() on the deferred beforeinstallprompt event.
  /// Returns true if prompt was triggered, false otherwise.
  Future<bool> promptInstall() => _impl.promptInstall();

  /// Reset dismissal count
  ///
  /// Clears the dismissal counter, allowing the install prompt
  /// to show again. Useful for settings/debug screens.
  void resetDismissals() => _impl.resetDismissals();

  /// Check if the PWA prompt has been shown this session
  bool get hasPromptedThisSession => _impl.hasPromptedThisSession;

  /// Mark that prompt was shown this session
  void markPromptShown() => _impl.markPromptShown();
}
