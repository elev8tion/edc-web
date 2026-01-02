/// Stub implementation for non-web platforms
///
/// This provides no-op implementations of all PWA install methods
/// for platforms that don't support PWA installation (iOS/Android native).
class PwaInstallServiceImpl {
  bool _hasPromptedThisSession = false;

  /// Initialize - no-op on non-web platforms
  void initialize() {}

  /// Always returns false on non-web platforms
  bool get canPrompt => false;

  /// Always returns false on non-web platforms
  bool get isInstalled => false;

  /// Always returns false on non-web platforms
  bool get isIOS => false;

  /// Always returns false on non-web platforms
  Future<bool> promptInstall() async => false;

  /// No-op on non-web platforms
  void resetDismissals() {}

  /// Check if prompt was shown this session
  bool get hasPromptedThisSession => _hasPromptedThisSession;

  /// Mark prompt as shown
  void markPromptShown() {
    _hasPromptedThisSession = true;
  }
}
