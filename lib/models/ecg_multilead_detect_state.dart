class EcgMultiLeadDetectState {
  final List<int> leadFlag;
  final int leadI;
  final int progress;
  final int heart;
  final int hrv;
  final int qt;

  EcgMultiLeadDetectState({
    required this.leadFlag,
    required this.leadI,
    required this.progress,
    required this.heart,
    required this.hrv,
    required this.qt,
  });

  factory EcgMultiLeadDetectState.fromJson(Map<String, dynamic> json) {
    return EcgMultiLeadDetectState(
      leadFlag: List<int>.from(json['leadFlag']),
      leadI: json['leadI'],
      progress: json['progress'],
      heart: json['heart'],
      hrv: json['hrv'],
      qt: json['qt'],
    );
  }
}
