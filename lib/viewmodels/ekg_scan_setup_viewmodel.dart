import 'dart:async';
import 'package:get/get.dart';
import '../core/enums/auto_reconnect_state.dart';
import '../core/storage/bluetooth_storage.dart';
import '../repositories/bluetooth_repository.dart';

class EkgScanSetupViewModel extends GetxController {

  final BluetoothRepository repository;
  final BluetoothStorage deviceStorage ;

  EkgScanSetupViewModel(this.repository, this.deviceStorage);

  final isDeviceConnected = false.obs;
  final isAutoConnecting = false.obs;

  StreamSubscription? _sub;
  bool _autoConnectTriggered = false;

  AutoReconnectState _reconnectState = AutoReconnectState.enabled;

  @override
  void onInit() {
    super.onInit();
    _listenRepoEvents();
    _tryAutoReconnect();
  }
  void _listenRepoEvents() {
    _sub = repository.events.listen((event) {
      print("🧪 EKG VM Event => $event");

      final status = event["status"];

      if (status == "connected") {
        isDeviceConnected.value = true;
        isAutoConnecting.value = false;
        // 🔥 IMPORTANT: manual connection restores auto-reconnect
        _reconnectState = AutoReconnectState.enabled;
        _autoConnectTriggered = false;
        print("✅ Device Connected");
      }

      if (status == "disconnected") {
        isDeviceConnected.value = false;

        if (_reconnectState != AutoReconnectState.enabled) {
          print("🛑 Auto reconnect blocked or paused");
          return;
        }
        _autoConnectTriggered = false; // allow auto reconnect ONLY if unexpected
        _tryAutoReconnect();
      }

      if (event.containsKey("mac")) {
        print("Check!!!!!: ${event.containsKey("mac")}");
        _handleAutoConnect(event);
      }
    });
  }
  void enableAutoReconnect() {
    if (_reconnectState == AutoReconnectState.blocked ||
        _reconnectState == AutoReconnectState.paused) {
      _reconnectState = AutoReconnectState.enabled;
      _autoConnectTriggered = false;
      print("🔓 Auto reconnect manually re-enabled");
    }
  }

  void _tryAutoReconnect() {
    if (_reconnectState != AutoReconnectState.enabled) return;
    if (Get.currentRoute == '/record_ekg') return;
    if (!repository.storage.hasDevice) return;

    isAutoConnecting.value = true;
    repository.startScan();
  }

  void _handleAutoConnect(Map event) {
    if (_reconnectState != AutoReconnectState.enabled) return;
    if (_autoConnectTriggered) return;
    if (!repository.storage.hasDevice) return;

    final foundMac = event["mac"];
    if (foundMac == repository.storage.lastMac) {
      _autoConnectTriggered = true;

      repository.connectDevice(
        mac: foundMac,
        name: repository.storage.lastName ?? "Unknown",
      );
    }
  }


  void goToHomeScreen() {
    Get.offAllNamed('/home');
  }

  Future<void> disconnect() async {
    _reconnectState = AutoReconnectState.blocked; // block reconnect permanently
    isAutoConnecting.value = false;
    deviceStorage.clear();
    await repository.disconnect();
  }


  @override
  void onClose() {
    super.onClose();
  }
  // User navigates to recording screen
  void startRecording() {
    _reconnectState = AutoReconnectState.paused; // pause auto-reconnect
    Get.toNamed('/record_ekg')?.then((_) {
      // Resume auto-reconnect when returning
      if (_reconnectState != AutoReconnectState.blocked) {
        _reconnectState = AutoReconnectState.enabled;
        _tryAutoReconnect();
      }
    });
  }

  void startHeartRate() {

  }

}

