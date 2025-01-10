import 'package:connectivity_plus/connectivity_plus.dart';


class NetworkService {
  final Connectivity _connectivity = Connectivity();

  // Stream to listen for connectivity changes
  Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((List<ConnectivityResult> event) {
      return event.isNotEmpty ? event[0] : ConnectivityResult.none;
    });
  }

  // Method to get the current network status
  Future<bool> get isOffline async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.none;
  }

  // Method to start monitoring network status
  Future<void> startMonitoring(Function onNetworkChanged) async {
    // Initial network check
    bool isOffline = await this.isOffline;

    // Notify about the current network status
    onNetworkChanged(isOffline);

    // Listen for network changes and notify the UI when the status changes
    connectivityStream.listen((event) {
      bool isOffline = event == ConnectivityResult.none;
      onNetworkChanged(isOffline);
    });
  }
}
