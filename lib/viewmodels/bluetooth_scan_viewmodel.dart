import 'dart:async';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../repositories/bluetooth_repository.dart';

class BluetoothScanViewModel extends GetxController {
  final BluetoothRepository repository;

  BluetoothScanViewModel(this.repository);

  // ---------------- State ----------------
  final RxList<Map<String, dynamic>> devices = <Map<String, dynamic>>[].obs;

  final isScanning = false.obs;
  final isConnecting = false.obs;
  final scanFinished = false.obs;

  final connectingDeviceName = "".obs;

  bool _hasNavigated = false;
  bool _autoConnectTriggered = false;


  StreamSubscription? _subscription;
  Timer? _timer;

  // ---------------- Lifecycle ----------------
  @override
  void onInit() {
    super.onInit();
    repository.startListening(); // 🔥 SAFE REATTACH
    _listenEvents();
    _requestPermissionsAndScan();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // ---------------- Permissions ----------------
  Future<void> _requestPermissionsAndScan() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    // startScan();
  }

  // ---------------- Scan ----------------
  void startScan() async {
    devices.clear();
    isScanning.value = true;
    scanFinished.value = false;
    _autoConnectTriggered = false;

    await repository.startScan();

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () {
      isScanning.value = false;
      scanFinished.value = true;
    });
  }

  // ---------------- Connect ----------------
  void connect(String mac, String name) async {
    isConnecting.value = true;
    connectingDeviceName.value = name;
    _hasNavigated = false;
// 🔐 Save device for future auto-connect
    repository.storage.saveDevice(mac: mac, name: name);


    await repository.connectDevice(mac: mac, name: name);

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 10), () {
      isConnecting.value = false;
    });
  }

  // ---------------- Event Handling ----------------
  void _listenEvents() {
    _subscription = repository.events.listen((event) {
      if (event is! Map) return;
        print("check111111111: $event");

      // Connection event
      if (event["status"] == "connected") {
        _onConnected();
      }
      // Device found
      if (event.containsKey("mac")) {
        final mac = event["mac"].toString();

        // Sanitize device name
        String name = "Unknown";
        if (event.containsKey("name")) {
          final rawName = event["name"]?.toString() ?? "";
          name = rawName.trim().isEmpty
              ? "Unknown"
              : rawName.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
        }

        // 🔥 FILTER: only ECG_PATCH
        // if (name.toUpperCase() != "ECG_PATCH") return;

        if (!devices.any((d) => d["mac"] == mac)) {
          devices.add({
            "mac": mac,
            "name": name,
          });
        }

        // ✅ Auto-connect logic (NOW mac & name exist)
        _tryAutoConnect(mac, name);
      }

    });
  }

// ---------------- Auto Connect ----------------
  void _tryAutoConnect(String mac, String name) {
    if (_autoConnectTriggered) return;
    if (!repository.storage.hasDevice) return;

    if (repository.storage.lastMac == mac) {
      _autoConnectTriggered = true;
      connect(mac, name);
    }
  }

  void _onConnected() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    isScanning.value = false;
    isConnecting.value = false;

    Get.offNamed('/ekg_setup');

  }
}
