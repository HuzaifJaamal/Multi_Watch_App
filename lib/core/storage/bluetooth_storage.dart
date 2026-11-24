import 'package:get_storage/get_storage.dart';

class BluetoothStorage {
  static const _box = 'bluetooth';
  static const _macKey = 'last_mac';
  static const _nameKey = 'last_name';

  final _storage = GetStorage(_box);

  void saveDevice({
    required String mac,
    required String name,
  }) {
    _storage.write(_macKey, mac);
    _storage.write(_nameKey, name);
    print("✅ Device saved: mac=$mac, name=$name");
  }

  String? get lastMac => _storage.read(_macKey);
  String? get lastName => _storage.read(_nameKey);

  void clear() {
    _storage.remove(_macKey);
    _storage.remove(_nameKey);
  }

  bool get hasDevice => lastMac != null;
}
