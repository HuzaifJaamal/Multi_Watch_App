import 'dart:convert';
import 'dart:io';

Map<String, List<double>> processLeadsInIsolate(String jsonPath) {
  final raw = File(jsonPath).readAsStringSync();
  final jsonData = jsonDecode(raw);

  final Map<String, dynamic> leadsJson = jsonData["leads"];

  String fix(String l) {
    l = l.toUpperCase();
    if (l == "AVR") return "aVR";
    if (l == "AVL") return "aVL";
    if (l == "AVF") return "aVF";
    return l;
  }

  final leads = <String, List<double>>{};
  leadsJson.forEach((name, arr) {
    final lead = fix(name);
    leads[lead] = (arr as List).map<double>((e) {
      if (e is Map && e.containsKey("value")) return (e["value"] as num).toDouble();
      return (e as num).toDouble();
    }).toList();
  });

  return leads;
}

