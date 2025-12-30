import 'package:flutter/foundation.dart';

class NavigationDebouncer {
  bool _isNavigating = false;
  final Duration cooldown;

  NavigationDebouncer({this.cooldown = const Duration(milliseconds: 500)});

  void navigate(AsyncCallback navigationAction) {
    if (_isNavigating) return;

    _isNavigating = true;
    navigationAction().whenComplete(() {
      Future.delayed(cooldown, () {
        _isNavigating = false;
      });
    });
  }
}
