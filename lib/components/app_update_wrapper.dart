import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/services/app_update_service.dart';
import 'app_update_dialog.dart';

/// Wrapper widget that listens for app updates and shows a dialog
class AppUpdateWrapper extends StatefulWidget {
  final Widget child;

  const AppUpdateWrapper({super.key, required this.child});

  @override
  State<AppUpdateWrapper> createState() => _AppUpdateWrapperState();
}

class _AppUpdateWrapperState extends State<AppUpdateWrapper> {
  StreamSubscription<bool>? _updateSubscription;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initUpdateListener();
    }
  }

  void _initUpdateListener() {
    final updateService = AppUpdateService.instance;

    // Listen for updates
    _updateSubscription = updateService.onUpdateAvailable.listen((available) {
      if (available && !_dialogShown && mounted) {
        _showUpdateDialog();
      }
    });

    // Check if update was already available before we started listening
    if (updateService.updateAvailable && !_dialogShown) {
      // Delay to ensure the app is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showUpdateDialog();
        }
      });
    }
  }

  Future<void> _showUpdateDialog() async {
    if (_dialogShown || !mounted) return;
    _dialogShown = true;

    final result = await showAppUpdateDialog(context);

    if (result == true) {
      // User chose to refresh
      AppUpdateService.instance.applyUpdate();
    } else {
      // User chose "Later" - reset flag so dialog can show again next session
      // But don't show again in this session
      debugPrint('[AppUpdateWrapper] User chose to update later');
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
