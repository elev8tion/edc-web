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
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!_connectivityController.isClosed) {
        // Connected if list is not empty and does NOT contain 'none' as the only element
        // Actually, if it contains 'none', it usually means no connection, but let's check properly
        // ConnectivityResult.none being in the list means disconnected?
        // Usually the list contains valid connections.
        final isConnected = results.any((result) => result != ConnectivityResult.none);
        _connectivityController.add(isConnected);
      }
    });

    // Check initial connectivity
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!_connectivityController.isClosed) {
        final isConnected = results.any((result) => result != ConnectivityResult.none);
        _connectivityController.add(isConnected);
      }
    } catch (e) {
      if (!_connectivityController.isClosed) {
        _connectivityController.add(false);
      }
    }
  }

  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}
