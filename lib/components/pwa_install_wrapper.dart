import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Wrapper widget that cleans up ?install=true URL parameter
/// Install prompt now shows after onboarding completion (unified_interactive_onboarding_screen.dart)
class PWAInstallWrapper extends StatefulWidget {
  final Widget child;

  const PWAInstallWrapper({super.key, required this.child});

  @override
  State<PWAInstallWrapper> createState() => _PWAInstallWrapperState();
}

class _PWAInstallWrapperState extends State<PWAInstallWrapper> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Clean up ?install=true param if present (no longer auto-triggers)
      // Install prompt now shows after onboarding completion
      _cleanInstallParam();
    }
  }

  void _cleanInstallParam() {
    final uri = Uri.base;
    final installParam = uri.queryParameters['install'];
    if (installParam == 'true') {
      debugPrint('[PWA Install] Cleaning install param from URL');
      _cleanUrl();
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
