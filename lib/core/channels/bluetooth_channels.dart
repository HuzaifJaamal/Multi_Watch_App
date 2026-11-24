import 'package:flutter/services.dart';

class BluetoothChannels {
  static const MethodChannel methodChannel =
  MethodChannel("com.example.bluetooth/scan");

  static const EventChannel eventChannel =
  EventChannel("com.example.bluetooth/unified_events");

}
