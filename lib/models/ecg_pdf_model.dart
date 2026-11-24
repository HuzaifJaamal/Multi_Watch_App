import 'ecg_data_point.dart';

class EcgPdfModel {
  final Map<String, List<EcgDataPoint>> leads;

  final int heartRate;
  final int qt;
  final int hrv;
  final String diagnosis;

  final DateTime? startTime;
  final DateTime? endTime;

  EcgPdfModel({
    required this.leads,
    required this.heartRate,
    required this.qt,
    required this.hrv,
    required this.diagnosis,
    required this.startTime,
    required this.endTime,
  });
}