class EcgDataPoint {
  final double value;
  final DateTime timestamp;

  EcgDataPoint({required this.value, required this.timestamp});

  // Convert EcgDataPoint to Map
  Map<String, dynamic> toJson() => {
    'value': value,
    'timestamp': timestamp.toIso8601String(),
  };

  // Convert Map to EcgDataPoint
  factory EcgDataPoint.fromJson(Map<String, dynamic> json) => EcgDataPoint(
    value: (json["value"] ?? double.nan).toDouble(),
    timestamp: DateTime.parse(json['timestamp']),
  );
}



