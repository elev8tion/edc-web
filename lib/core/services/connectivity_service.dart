import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamController<bool> _connectivityController;

  ConnectivityService() {
    _connectivityController = StreamController<bool>.broadcast();
    _initConnectivity();
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (!_connectivityController.isClosed) {
        _connectivityController.add(result != ConnectivityResult.none);
      }
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (!_connectivityController.isClosed) {
        _connectivityController.add(result != ConnectivityResult.none);
      }
    } catch (e) {
      if (!_connectivityController.isClosed) {
        _connectivityController.add(false);
      }
    }
  }

  Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}
