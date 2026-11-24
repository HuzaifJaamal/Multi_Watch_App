import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

enum NetworkStatus { wifi, mobile, none }

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();

  final Rx<NetworkStatus> networkStatus = NetworkStatus.none.obs;

  @override
  void onInit() {
    super.onInit();

    _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });

    checkInitialConnection();
  }

  Future<void> checkInitialConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      networkStatus.value = NetworkStatus.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      networkStatus.value = NetworkStatus.mobile;
    } else {
      networkStatus.value = NetworkStatus.none;
    }
  }

  bool get hasInternet => networkStatus.value != NetworkStatus.none;
}
