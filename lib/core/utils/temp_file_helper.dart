import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../models/ecg_data_point.dart';

Future<String> writeEcgLeadsToTempJson(
    Map<String, List<EcgDataPoint>> ecgLeads,
    ) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/ecg_${DateTime.now().millisecondsSinceEpoch}.json',
  );

  final json = {
    "generated_at": DateTime.now().toIso8601String(),
    "heartRate": 72,
    "qt": 350,
    "hrv": 50,
    "diagnosis": "Normal",
    "leads": ecgLeads.map(
          (lead, points) => MapEntry(
        lead,
        // points.map((p) => p.toJson()).toList(),
        points
            .where((p) => !p.value.isNaN)
            .map((p) => p.toJson())
            .toList()
      ),
    ),
    "metadata": {
      "device_mac": "12:D4:3A:03:84:B5",
      "ecg_start_time": "Time: 16:09:07 (2026-Jan-20)",
      "ecg_end_time": "Time: 16:09:51 (2026-Jan-20)",
      "duration_seconds": 43,
    },
  };

  await file.writeAsString(jsonEncode(json));
  return file.path;
}
