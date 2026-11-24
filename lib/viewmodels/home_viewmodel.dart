import 'dart:async';
import 'package:get/get.dart';
import '../core/storage/bluetooth_storage.dart';
import '../models/user_model.dart';
import '../repositories/bluetooth_repository.dart';

class HomeViewModel extends GetxController {

  final BluetoothStorage deviceStorage ;
  final BluetoothRepository deviceDisconnect ;

  HomeViewModel({
    required this.deviceStorage,
    required this.deviceDisconnect,
  });
  RxInt currentIndex = 0.obs;
  Rxn<UserModel> user = Rxn<UserModel>();
  final isDeviceConnected = false.obs;

  StreamSubscription? _btSub;

  @override
  void onInit() {
    super.onInit();
    _listenBleEvents();

  }
  void _listenBleEvents() {
    // 👂 Listen to bluetooth connection
    _btSub = deviceDisconnect.events.listen((event) {
      if (event.containsKey('status')) {
        isDeviceConnected.value = event['status'] == 'connected';
        print("🏠 Home connection = ${isDeviceConnected.value}");
      }

      if (event['state'] == 'off' || event['bluetooth'] == 'off') {
        isDeviceConnected.value = false;
      }
    });
  }
  @override
  void onReady() {
    super.onReady();
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void goToBluetoothScanPage() {
    Get.offAllNamed('/bluetoothScanPage');
  }

  Future<void> logout() async {
    deviceStorage.clear();
    deviceDisconnect.disconnect();

    Get.offAllNamed("/login");
  }
}
