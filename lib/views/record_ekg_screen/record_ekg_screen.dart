import 'package:lottie/lottie.dart';
import 'widgets/chart_helper.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_color.dart';
import '../../core/dialogs/custom_dialog.dart';
import '../../viewmodels/ecg_export_viewmodel.dart';
import '../../viewmodels/record_ekg_viewmodel.dart';
import '../pdf/pdf_preview_screen.dart';

class RecordEkgScreen extends StatefulWidget {
  const RecordEkgScreen({super.key});

  @override
  State<RecordEkgScreen> createState() => _RecordEkgScreenState();
}

class _RecordEkgScreenState extends State<RecordEkgScreen> {
  final controller = Get.find<RecordEkgViewModel>();
  final exportVm = Get.find<EcgExportViewModel>();

  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    return
      WillPopScope(
          onWillPop: () async {

            // 🔒 Prevent back while loading
            if (exportVm.isGenerating.value) return false;

            return false; // ✅ Allow app exit
          },
          child: SafeArea(
            child: Stack(
              children: [
                /// 🔹 Main Screen
                Scaffold(
                  appBar: _buildAppBar(),
                  body: Stack(
                    children: [
                      buildMainUI(context),
                      buildDialogUI(context),
                  ],
                ),
                          ),
                /// 🔥 FULL SCREEN LOADING OVERLAY
                Obx(() {
                  if (!exportVm.isGenerating.value) {
                    return const SizedBox.shrink();
                  }

                  return AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      child:
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 140,
                              child: Lottie.asset("assets/lottie/loading.json", repeat: true),
                            ),
                            // CircularProgressIndicator(color: AppColors.whiteGhost),
                            const SizedBox(height: 12),
                            Text(
                              exportVm.progressText.value,
                              // "Generating PDF Please wait....",
                              style: TextStyle(
                                color: AppColors.whiteGhost,
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
      )
    );
  }



// =================== APP BAR ===================
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        "Record ECG",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        Obx(() => Row(
          children: [
            Icon(
              controller.isDeviceConnected.value
                  ? Icons.check_circle
                  : Icons.cancel,
              color: controller.isDeviceConnected.value
                  ? AppColors.primary
                  : AppColors.red,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              controller.isDeviceConnected.value
                  ? "Connected"
                  : "Disconnected",
              style: TextStyle(
                color: controller.isDeviceConnected.value
                    ? AppColors.primary
                    : AppColors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
          ],
        )),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Obx(() => _buildProgressBar()),
      ),
    );
  }

  // =================== MAIN UI ===================
  Widget buildMainUI(BuildContext context) {
    return Column(
      children: [
        _buildVitals(),
        Expanded(child: _buildCharts(context)),
        // _buildPdfButton(),
      ],
    );
  }
  // =================== Dialog UI ===================
  Widget buildDialogUI(BuildContext context) {
    return Obx(() {
      // 🔴 DISCONNECT DIALOG
      if (controller.showDisconnectDialog.value && !_dialogShown) {
        _dialogShown = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          controller.showDisconnectDialog.value = false;

          showCustomStatusDialog(
            context: context,
            icon: Icons.bluetooth_disabled,
            iconColor: AppColors.primary,
            title: "Device Disconnected",
            message: "Bluetooth device has been disconnected. Please reconnect.",
            textAlign: TextAlign.center,
            buttonText1: "Reconnect",
            buttonText2: "Cancel",
            onButtonTap: () {
              _dialogShown = false;
              controller.goToScanPage();
            },
            onButton2Tap: () {
              _dialogShown = false;
              controller.goToHomeScreen();
            },
          );
        });
      }

      // 🟡 POSTURE DIALOG
      if (controller.showPostureDialog.value && !_dialogShown) {
        _dialogShown = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          controller.showPostureDialog.value = false;

          showCustomStatusDialog(
            context: context,
            icon: Icons.error_outline,
            iconColor: AppColors.primary,
            title: "Posture Issue",
            message:
            "Your posture is not good. Please set the device posture first.",
            textAlign: TextAlign.center,
            buttonText1: "OK",
            onButtonTap: () {
              _dialogShown = false;
              controller.goToEkgScanSetupScreen();
            },
          );
        });
      }

      return const SizedBox.shrink();
    });
  }


  // =================== VITALS ===================
  Widget _buildVitals() {
    return Obx(() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _vitalTile("Heart Rate", "${controller.heartRate.value} BPM"),
          _vitalTile("QT Interval", "${controller.qt.value} ms"),
          _vitalTile("HRV", "${controller.hrv.value} ms"),
        ],
      ),
    ));
  }


  Widget _vitalTile(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
  // =================== CHARTS ===================
  Widget _buildCharts(BuildContext context) {
    return Obx(() {
      final data = controller.ecgDataLists;
      final offsets = controller.writeIndex;
      // final gain = controller.gain.value;
      // print("Check Screen!!!!! $offsets");
      return SingleChildScrollView(
        child: Column(
          children: [
            buildLeadChart(context, "I", data["I"] ?? [], offsets["I"] ?? 0, ),
            buildLeadChart(context, "II", data["II"] ?? [], offsets["II"] ?? 0, ),
            buildLeadChart(context, "III", data["III"] ?? [], offsets["III"] ?? 0, ),
            buildLeadChart(context, "aVR", data["AVR"] ?? [], offsets["AVR"] ?? 0, ),
            buildLeadChart(context, "aVL", data["AVL"] ?? [], offsets["AVL"] ?? 0, ),
            buildLeadChart(context, "aVF", data["AVF"] ?? [], offsets["AVF"] ?? 0, ),
            // buildLeadChart(context, "aVF", data["AVF"] ?? [], offsets["AVF"] ?? 0, AppColors.red),
            _buildPdfButton(),
          ],
        ),
      );
    });
  }



  // =================== PDF ===================
  Widget _buildPdfButton() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 32,
        child:
        Obx(() {
          final pdfPath = exportVm.lastGeneratedPath;

          if (exportVm.hasGenerated.value && pdfPath != null) {
            return Row(
              spacing: 12,
              // runSpacing: 12,
              // alignment: WrapAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text("Show PDF"),
                  onPressed: () async {
                    await Get.to(
                          () => PdfPreviewScreen(pdfPath: pdfPath),
                    );
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    controller.goToEkgScanSetupScreen();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whiteGhost,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    'Record Again',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }

          return ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(
              controller.isRecording.value
                  ? "Recording..."
                  : "Generate PDF",
            ),
            onPressed: controller.isRecording.value
                ? null
                : controller.generatePdfFromCurrentEcg,
          );

          /*return ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("Generate PDF"),
            onPressed: controller.generatePdfFromCurrentEcg,
          );*/
        }),
      ),
    );
  }

  // =================== PROGRESS ===================
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child:  (controller.isTestingMode.value && !controller.isTestingComplete.value)
            ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: controller.progress.value,
                    backgroundColor: AppColors.grey,
                    valueColor:
                    AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 32,
                  ),
                ),
            FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(controller.progress.value * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteGhost,
                    ),
                  ),
                  Text(
                    "Device Initializing......",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.whiteGhost,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const
                  Padding(
                   padding: EdgeInsets.only(left: 16),
                    child: Text(
                    "Recording",
                    style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  // "${controller.detectProgress.value}%",
                  "${controller.uiProgress.value}%",
                  // "${_seconds} sec",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteGhost,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
