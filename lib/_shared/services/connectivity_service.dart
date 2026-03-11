/// Abstract connectivity service — monitors device network state.
///
/// Implementations: `RealConnectivityService` (uses connectivity_plus)
/// and `FakeConnectivityService` (for testing).
abstract class ConnectivityService {
  /// Whether the device is currently online.
  bool get isOnline;

  /// Stream that emits `true` when online, `false` when offline.
  Stream<bool> get onConnectivityChanged;
}
