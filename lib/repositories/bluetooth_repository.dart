import 'dart:async';
import '../core/channels/bluetooth_channels.dart';
import '../core/storage/bluetooth_storage.dart';
import '../models/bluetooth_device.dart';

class BluetoothRepository {
  // ================= SINGLETON =================
  BluetoothRepository._internal() {
    startListening(); // 🔥 attach EventChannel ONCE
  }

  static final BluetoothRepository instance =
  BluetoothRepository._internal();

  // =============================================
  final BluetoothStorage storage = BluetoothStorage();

  StreamSubscription? _subscription;

  /// Public stream controller
  final StreamController<Map<String, dynamic>> _eventController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// Start listening to native events
  void startListening() {
    if (_subscription != null) return;

    _subscription =
        BluetoothChannels.eventChannel.receiveBroadcastStream().listen(
              (event) {
                if (event is Map) {
                  print("📡 Native Event => $event");
                  _eventController.add(Map<String, dynamic>.from(event));
                }
          },
          onError: (error) {
            _eventController.addError(error);
          },
        );
  }

  /// ❌ DO NOT EVER STOP LISTENING
  void stopListening() {}


  /// 🔍 Start BLE Scan
  Future<void> startScan() async {
    await BluetoothChannels.methodChannel.invokeMethod('startScan');
  }

  /// 🔗 Connect Device
  Future<void> connectDevice({
    required String mac,
    required String name,
  }) async {
    await BluetoothChannels.methodChannel.invokeMethod(
      'connectDevice',
      {
        'mac': mac,
        'name': name,
      },
    );
  }
  // ---------------- ECG FLOW ----------------
  Future<void> startEcgSession() async {
    await BluetoothChannels.methodChannel.invokeMethod('startECG');
  }
  Future<void> stopEcg() async {
    await BluetoothChannels.methodChannel.invokeMethod('stopECG');
  }

  /// ❌ Disconnect
  Future<void> disconnect() async {
    await BluetoothChannels.methodChannel.invokeMethod('disconnect');
  }




  /// Parse Bluetooth device from native event
  BluetoothDeviceModel? parseDevice(dynamic event) {
    if (event is Map &&
        event.containsKey('name') &&
        event.containsKey('mac')) {
      return BluetoothDeviceModel.fromMap(event);
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _eventController.close();
  }
}

