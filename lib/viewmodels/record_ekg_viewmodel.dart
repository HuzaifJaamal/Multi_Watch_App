import 'dart:async';
import 'package:get/get.dart';
import '../core/snack_bar/snack_bar_error.dart';
import '../core/utils/temp_file_helper.dart';
import '../models/ecg_pdf_model.dart';
import '../models/ecg_data_point.dart';
import '../models/ecg_multilead_detect_state.dart';
import '../repositories/bluetooth_repository.dart';
import '../repositories/record_repository.dart';
import 'ecg_export_viewmodel.dart';
import 'ekg_scan_setup_viewmodel.dart';


class RecordEkgViewModel extends GetxController {
  final BluetoothRepository repository;
  final EcgRepository recordRepo;
  final EcgExportViewModel exportVm;

  RecordEkgViewModel(
      this.repository,
      this.recordRepo,
      this.exportVm,
      );

// Viewport offset per lead
  final RxMap<String, int> writeIndex = <String, int>{}.obs;


  /// Window size (samples visible)
  final int windowSize = 1000;

  // ---------------- UI STATE ----------------
  final isDeviceConnected = true.obs;
  final isTestingMode = true.obs;
  final isTestingComplete = false.obs;

  final progress = 0.0.obs;
  final progressText = "ECG Recording......".obs;

  final heartRate = 0.obs;
  final qt = 0.obs;
  final hrv = 0.obs;
  final detectProgress = 0.obs;
  final RxDouble gain = 1.0.obs;
  final isRecording = false.obs;

  // ---------------- ECG DATA ----------------
  // Rolling window for UI (1000 points)
  final ecgDataLists = <String, List<EcgDataPoint>>{}.obs;

// 🔥 Full data for saving (ALL points)
  final fullEcgDataLists = <String, List<EcgDataPoint>>{};

  late EcgPdfModel model;

  final RxBool showDisconnectDialog = false.obs;
  final RxBool showPostureDialog = false.obs;
  final uiProgress = 0.obs; // replace detectProgress in UI


  final pendingLeadData = <String, List<int>>{};
  final List<EcgMultiLeadDetectState> _ecgStateBuffer = [];


  // ---------------- INTERNAL ----------------
  StreamSubscription? _eventSub;
  Timer? _progressTimer;
  Timer? _ecgStreamTimer;


  bool skipInitialData = true;
  bool postureDialogShown = false;
  DateTime? skipStartTime;
  final int skipSeconds = 8;
  int detectSeconds = 0;
  int leadOffCount = 0;
  bool isDetecting = true;
  bool isStreaming = false;
  static const int gapSize = 20;
  static const int ecgIntervalMs = 4;       // ECG plotting
  static const int vitalsIntervalMs = 200; // vitals update (1 Hz)
  static const int penGapSize = 18; // 5–10 recommended
  String? lastSavedJsonPath;

  bool ecgCompleted = false;
  DateTime _lastCompletionCheck =
  DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? ecgStartTime;
  DateTime? ecgEndTime;

  bool _startTimeCaptured = false;
  // ---------------- HEART RATE ANALYSIS ----------------
  final List<int> _heartRateSamples = [];
  bool _diagnosisLocked = false;

  String diagnosis = "Normal sinus rhythm"; // default
  static const int minHrSamples = 5; // avoid early noise
  String? _lastDiagnosis;

  bool _buffersEmpty() {
    return pendingLeadData.values.every((buffer) => buffer.isEmpty);
  }

  @override
  void onInit() {
    super.onInit();
    _initBuffers();
    startEcgSession();
    // 👂 Listen to connection changes
    ever<bool>(isDeviceConnected, _onConnectionChanged);
  }

  @override
  void onClose() {
    _eventSub?.cancel();
    _progressTimer?.cancel();
    _ecgStreamTimer?.cancel();
    showDisconnectDialog.value = false;
    isStreaming = false;
    super.onClose();
  }

  // ---------------- INIT ----------------
  void _initBuffers() {
    for (final lead in ["I", "II", "III", "AVR", "AVL", "AVF"]) {
      ecgDataLists[lead] = List.generate(
        windowSize,
            (_) => EcgDataPoint(value: 0, timestamp: DateTime.now()),
      );

      // 🔥 Full data for saving
      fullEcgDataLists[lead] = [];

      pendingLeadData[lead] = [];
      writeIndex[lead] = 0;
    }
  }

  void setGain(double value) {
    gain.value = value;
  }

// ---------------- Dialog Box ----------------
  // 🔔 React to connection changes
  void _onConnectionChanged(bool isConnected) {
    if (!isConnected) {

      showDisconnectDialog.value = true;
    }
  }

  // ---------------- ECG FLOW ----------------
  Future<void> startEcgSession() async {
    isRecording.value = true;
    _startProgress();
    await repository.startEcgSession();
    _listenToEvents();
    // _startThrottleTimer();
    startStreaming();
  }

  Future<void> stopEcg() async {
    await repository.stopEcg();
  }

  // ---------------- PROGRESS ----------------
  void _startProgress() {
    progress.value = 0;
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 170),
          (timer) {
        progress.value += 0.02;
        if (progress.value >= 1) {
          progress.value = 1;
          isTestingMode.value = false;
          isTestingComplete.value = true;
          timer.cancel();
        }
      },
    );
  }

  // ---------------- EVENTS ----------------
  void _listenToEvents() {
    skipInitialData = true;
    skipStartTime = DateTime.now();
    _eventSub = repository.events.listen((event) {
      if (event is! Map<String, dynamic>) return;

      print("📡 EVENT: $event");

      // 🔕 Bluetooth OFF
      if (event['state'] == 'off' || event['bluetooth'] == 'off') {
        isDeviceConnected.value = false;
        return;
      }

      // 🔌 Connection
      if (event.containsKey('status')) {
        _handleConnection(event);
        return;
      }

      // 🧠 ECG State
      if (event['type'] == 'state') {
        _handleEcgState(event);
        return;
      }

      // 🫀 ECG Data
      if (event.containsKey('lead') && event.containsKey('data')) {
        _handleEcgData(event);
        return;
      }
    });
  }


// --------------------------------------------------
  // HANDLERS
  // --------------------------------------------------

  void _handleConnection(Map<String, dynamic> event) {
    isDeviceConnected.value = event['status'] == 'connected';
  }

  void _handleEcgState(Map<String, dynamic> event) {

    final state = EcgMultiLeadDetectState.fromJson(event);
    // Buffer incoming state
    _ecgStateBuffer.add(state);

    // Prevent memory leak
    if (_ecgStateBuffer.length > 200) {
      _ecgStateBuffer.removeAt(0);
    }
    if (!isDetecting) return;

    detectSeconds++;

    // Start detecting lead-off after 3 seconds
    if (detectSeconds > 3) {
      bool isLeadOff = state.leadI == 1;

      if (isLeadOff) {
        leadOffCount++;

        if (leadOffCount > 2) {   // lead off stable for ~2 readings
          if (!postureDialogShown) {
            postureDialogShown = true;

            stopEcg();
            isDetecting = false;

            showPostureDialog.value = true; // 🔔 notify UI
          }

        }
      } else {
        leadOffCount = 0; // reset if posture becomes correct
      }
    }

  }
  double _averageHeartRate() {
    if (_heartRateSamples.isEmpty) return 0;
    final sum = _heartRateSamples.reduce((a, b) => a + b);
    return sum / _heartRateSamples.length;
  }
  String _diagnoseFromAverage(double avgHr) {
    if (avgHr < 60) {
      return "Bradycardia";
    } else if (avgHr <= 100) {
      return "Normal Rhythm";
    } else {
      return "Tachycardia";
    }
  }


  void _handleEcgData(Map<String, dynamic> payload) {
    final lead = payload['lead'];
    final data = (payload['data'] as List).cast<int>();
    print("Check Lead Name: $lead");
    print("Check Lead data: $data");

    if (skipInitialData) {
      final elapsed =
          DateTime.now().difference(skipStartTime!).inSeconds;
      if (elapsed < skipSeconds) return;
      skipInitialData = false;
    }

    pendingLeadData[lead]?.addAll(data);

    isStreaming = true;
  }
  // --------------------------------------------------
  // 2️⃣ THROTTLED CHART UPDATES (PERFORMANCE 🔥)
  // --------------------------------------------------

  void startStreaming()  {
    if (_ecgStreamTimer != null) return;

    _ecgStreamTimer = Timer.periodic(
      const Duration(milliseconds: ecgIntervalMs),
          (_) async {
        if (!isStreaming) return;

        final now = DateTime.now();
        bool ecgUpdated = false;

        // ================= ECG PLOTTING =================
        pendingLeadData.forEach((lead, buffer) {
          if (buffer.isEmpty) return;

          // ✅ Capture ECG start time ONCE
          if (!_startTimeCaptured) {
            ecgStartTime = now;
            _startTimeCaptured = true;
            print("🟢 ECG STARTED at $ecgStartTime");
          }

          final index = writeIndex[lead] ?? 0;
          final value = buffer.removeAt(0);


          final point = (index < penGapSize)
              ? EcgDataPoint(value: double.nan, timestamp: now)
              : EcgDataPoint(value: value.toDouble(), timestamp: now);

            // UI rolling buffer (1000)
          ecgDataLists[lead]![index] = point;

            // 🔥 FULL DATA APPEND (NO LIMIT)
          fullEcgDataLists[lead]!.add(point);


          writeIndex[lead] = (index + 1) % windowSize;
          ecgUpdated = true;
        });

        // ================= VITALS =================
        if (_ecgStateBuffer.isNotEmpty) {
          final latestState = _ecgStateBuffer.last;

          heartRate.value = latestState.heart;
          qt.value = latestState.qt;
          hrv.value = latestState.hrv;

          // ---------------- COLLECT HEART RATE ----------------
          if (!_diagnosisLocked && latestState.heart > 0) {
            _heartRateSamples.add(latestState.heart);

            // Optional safety
            if (_heartRateSamples.length > 300) {
              _heartRateSamples.removeAt(0);
            }

            // Update diagnosis ONLY after enough samples
            final avgHr = _averageHeartRate();
            final newDiagnosis = _diagnoseFromAverage(avgHr);

            if (newDiagnosis != _lastDiagnosis) {
              diagnosis = newDiagnosis;
              _lastDiagnosis = newDiagnosis;

              print("🫀 Avg HR: ${avgHr.toStringAsFixed(1)} → $diagnosis");
            }
          }


          int deviceProgress = latestState.progress.clamp(0, 100);

          // Hold at 99% until plotting completes
          if (deviceProgress >= 100 && !_buffersEmpty()) {
            uiProgress.value = 98;
          } else {
            uiProgress.value = deviceProgress;
          }

          // ================= COMPLETION CHECK =================
          if (!ecgCompleted &&
              latestState.progress >= 100 &&
              _buffersEmpty() &&
              now.difference(_lastCompletionCheck).inMilliseconds > vitalsIntervalMs) {

            _lastCompletionCheck = now;
            ecgCompleted = true;

            ecgEndTime = now;
            print("🔴 ECG ENDED at $ecgEndTime");

            uiProgress.value = 100; // 🔥 NOW allow 100%
            print("✅ ECG COMPLETED (plotting synchronized)");
            _diagnosisLocked = true;
            // saveSession();
            fullEcgDataLists.forEach((lead, list) {
              print("📦 FINAL Lead $lead -> total saved points: ${list.length}");
            });
            showSnackBarSuccess("Success 👏", "ECG Recording Completed");
            isRecording.value = false;
          }
        }

        // ================= UI REFRESH =================
        if (ecgUpdated) {
          ecgDataLists.refresh();
          writeIndex.refresh();
        }
      },
    );
  }

  Future<void> generatePdfFromCurrentEcg() async {
    if (fullEcgDataLists.isEmpty) {
      showSnackBarError(
        "No ECG",
        "No ECG data available",
      );
      return;
    }

    final exportVm = Get.find<EcgExportViewModel>();

    final pdfModel = EcgPdfModel(
      heartRate: heartRate.value,
      qt: qt.value,
      hrv: hrv.value,
      diagnosis: diagnosis,
      startTime: ecgStartTime,
      endTime: ecgEndTime,
      leads: fullEcgDataLists
    );

    final jsonPath =
    await writeEcgLeadsToTempJson(fullEcgDataLists);

    await exportVm.generatePdf(
      jsonPath,
      pdfModel,
    );

    showSnackBarSuccess(
      "Success 👏",
      "PDF Generated",
    );
  }

  void goToHomeScreen() {
    Get.offAllNamed('/home');
  }
  void goToEkgScanSetupScreen() {
    Get.offAllNamed('/ekg_setup');
  }

  void goToScanPage() {
    Get.delete<RecordEkgViewModel>(force: true);
    final setupVM = Get.find<EkgScanSetupViewModel>();
    setupVM.enableAutoReconnect(); // 👈 add this
    Get.offAllNamed('/bluetoothScanPage');
  }
}
