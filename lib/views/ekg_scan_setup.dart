import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_color.dart';
import '../../viewmodels/ekg_scan_setup_viewmodel.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';

import '../core/dialogs/custom_dialog.dart';

class EkgScanSetupScreen extends GetView<EkgScanSetupViewModel> {
  const EkgScanSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // bool confirm = false;
          final connected = controller.isDeviceConnected.value;
          if (connected) {
            await showCustomStatusDialog(
              context: context,
              icon: Icons.warning,
              iconColor: AppColors.primary,
              title: "Disconnect Device",
              message: "Are you sure you want to disconnect?",
              textAlign: TextAlign.center,
              buttonText1: "Yes",
              buttonText2: "Cancel",
              onButtonTap: () async {
                print("✅ User confirmed,Device Disconnet...");

                await controller.disconnect();   // 🔥 CALL the method
                controller.goToHomeScreen();
              },      // Main action (Yes)
              onButton2Tap: () {},     // Cancel action
            );

          } else {
            controller.goToHomeScreen();

            print("🔌 Device disconnected.");
          }

        }
      },
      child: Scaffold(
        // backgroundColor: Colors.white,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final connected = controller.isDeviceConnected.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Header ----------------
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          final connected = controller.isDeviceConnected.value;
                          if (connected) {
                            await showCustomStatusDialog(
                              context: context,
                              icon: Icons.warning,
                              iconColor: AppColors.primary,
                              title: "Disconnect Device",
                              message: "Are you sure you want to disconnect?",
                              textAlign: TextAlign.center,
                              buttonText1: "Yes",
                              buttonText2: "Cancel",
                              onButtonTap: () async {
                                print("✅ User confirmed,Device Disconnet...");

                                await controller.disconnect();   // 🔥 CALL the method
                                controller.goToHomeScreen();
                              },      // Main action (Yes)
                              onButton2Tap: () {},     // Cancel action
                            );

                          } else {
                            controller.goToHomeScreen();

                            print("🔌 Device disconnected.");
                          }
                        },
                      ),
                      const Text(
                        "ECG Scan Setup",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      connected
                          ? Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.teal),
                              SizedBox(width: 4),
                              Text("Connected"),
                        ],
                      )
                          : Row(
                            children: const [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 4),
                              Text("Disconnected",style: TextStyle(color: Colors.red),),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Get ready to record ECG",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _step(Icons.bluetooth, "Ensure your device is connected"),
                  _step(Icons.chair, "Sit still in a quiet place"),
                  _step(Icons.mic_off, "Avoid speaking during scan"),

                  const Spacer(),

                  // ---------------- Start Button ----------------
                  Center(
                    child: connected
                        ? RippleAnimation(
                          repeat: true,
                          color: AppColors.primary.withOpacity(0.3),
                          minRadius: 30,
                          ripplesCount: 3,
                          child: _startButton(true),
                    )
                        : _startButton(false),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(
                    connected
                    ? "Recording..."
                        : "Start Heart Rate",
                    ),
                    onPressed: connected
                    ? null
                        : controller.startHeartRate,
                  ),

                  Center(
                    child: Text(
                      connected
                          ? "Device Connected"
                          : "Device Not Connected",
                      style: TextStyle(
                        color: connected ? Colors.teal : Colors.red,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _startButton(bool enabled) {
    return SizedBox(
      width: 120,
      height: 120,
      child: ElevatedButton(
        onPressed: enabled ? controller.startRecording : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.whiteGhost,
          shape: const CircleBorder(),
          elevation: 0,
          side: BorderSide(
            color: enabled ? Colors.teal : Colors.red,
            width: 5,
          ),
        ),
        child: const Text(
          "Start\nRecording",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _step(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

