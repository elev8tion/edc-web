import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../core/navigation/navigation_service.dart';
import 'pwa_install_dialog.dart';

/// Wrapper widget that checks for ?install=true URL parameter and shows install dialog
class PWAInstallWrapper extends StatefulWidget {
  final Widget child;

  const PWAInstallWrapper({super.key, required this.child});

  @override
  State<PWAInstallWrapper> createState() => _PWAInstallWrapperState();
}

class _PWAInstallWrapperState extends State<PWAInstallWrapper> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkForInstallParam();
    }
  }

  void _checkForInstallParam() {
    // Check if user came from landing page with ?install=true parameter
    final uri = Uri.base;
    final installParam = uri.queryParameters['install'];
    debugPrint('[PWA Install] Checking URL: ${uri.toString()}');
    debugPrint('[PWA Install] Install param: $installParam');

    if (installParam == 'true') {
      debugPrint('[PWA Install] Install param detected - scheduling dialog');
      // Wait for splash screen to finish (it takes ~2-3 seconds)
      // then show the dialog
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && !_dialogShown) {
          debugPrint('[PWA Install] Attempting to show dialog now');
          _showInstallDialog();
        }
      });
    }
  }

  Future<void> _showInstallDialog() async {
    if (_dialogShown) return;
    _dialogShown = true;

    // Use the navigator's context which is guaranteed to have a valid overlay
    final navigatorContext = NavigationService.navigatorKey.currentContext;
    if (navigatorContext == null) {
      debugPrint('[PWA Install] ERROR: No navigator context available');
      _dialogShown = false;
      return;
    }

    // Detect iOS for showing manual instructions
    final isIOS = _detectIOS();
    debugPrint('[PWA Install] Showing install dialog (iOS: $isIOS)');

    await showPWAInstallDialog(navigatorContext, isIOS: isIOS);

    // Clean up the URL to remove the ?install=true parameter
    _cleanUrl();
  }

  bool _detectIOS() {
    try {
      final userAgent = web.window.navigator.userAgent.toLowerCase();
      // iOS Safari detection
      final isIOSDevice = userAgent.contains('iphone') ||
          userAgent.contains('ipad') ||
          userAgent.contains('ipod');
      // Not Chrome on iOS (which also can't install PWAs programmatically)
      return isIOSDevice;
    } catch (e) {
      debugPrint('[PWA] Could not detect platform: $e');
      return false;
    }
  }

  void _cleanUrl() {
    try {
      // Remove the ?install=true parameter from URL
      final uri = Uri.base;
      final newParams = Map<String, String>.from(uri.queryParameters)
        ..remove('install');

      String newUrl;
      if (newParams.isEmpty) {
        newUrl = uri.origin + uri.path;
      } else {
        newUrl = uri.replace(queryParameters: newParams).toString();
      }

      // Update the browser URL without reloading
      web.window.history.replaceState(null, '', newUrl);
      debugPrint('[PWA] Cleaned URL: $newUrl');
    } catch (e) {
      debugPrint('[PWA] Could not clean URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
