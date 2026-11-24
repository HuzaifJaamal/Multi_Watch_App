class BluetoothDeviceModel {
  final String name;
  final String mac;
  final int? rssi;

  const BluetoothDeviceModel({
    required this.name,
    required this.mac,
    this.rssi,
  });

  /// From native EventChannel map
  factory BluetoothDeviceModel.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDeviceModel(
      name: map['name']?.toString() ?? 'Unknown',
      mac: map['mac']?.toString() ?? '',
      rssi: map['rssi'] is int ? map['rssi'] : null,
    );
  }

  /// Convert to Map (if needed later)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mac': mac,
      'rssi': rssi,
    };
  }

  @override
  String toString() =>
      'BluetoothDeviceModel(name: $name, mac: $mac, rssi: $rssi)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BluetoothDeviceModel &&
              runtimeType == other.runtimeType &&
              mac == other.mac;

  @override
  int get hashCode => mac.hashCode;
}
