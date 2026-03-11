import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_service.dart';

/// Production connectivity service backed by connectivity_plus.
class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  late final StreamController<bool> _controller;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  ConnectivityServiceImpl() {
    _controller = StreamController<bool>.broadcast();
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });

    // Check initial state
    _connectivity.checkConnectivity().then((results) {
      _isOnline = !results.contains(ConnectivityResult.none);
    });
  }

  @override
  bool get isOnline => _isOnline;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Clean up listeners.
  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
