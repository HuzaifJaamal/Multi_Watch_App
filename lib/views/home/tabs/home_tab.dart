import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_color.dart';
import '../../../core/dialogs/custom_dialog.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../widgets/home_header.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {

    final homeVM = Get.find<HomeViewModel>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // bool confirm = false;

          showCustomStatusDialog(
            context: context,
            icon: Icons.warning,
            iconColor: AppColors.primary,
            title: "Logout",
            message: "Are you sure you want to logout?",
            textAlign: TextAlign.center,
            buttonText1: "Yes",
            buttonText2: "Cancel",

            /// ✅ YES ACTION
            onButtonTap: () async {
              print("✅ User confirmed, App Logout...");

              Get.back(); // 🔑 Close dialog first
              await homeVM.logout(); // 🔑 CALL the method
            },

            /// ❌ CANCEL ACTION
            onButton2Tap: () {
              Get.back(); // just close dialog
            },
          );

        }
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                children: [
                  HomeHeader(),
                  SizedBox(height: 16),
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.whiteGhost,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: () async {
                      final homeVM = Get.find<HomeViewModel>();
                      print("🔌 Device connected: ${homeVM.isDeviceConnected.value}");
                      // ✅ Device already connected → skip dialog
                      if (homeVM.isDeviceConnected.value == true) {
                        Get.toNamed('/ekg_setup');
                        return;
                      }

                      // ❌ Not connected → show confirmation dialog
                      await showCustomStatusDialog(
                        context: context,
                        icon: Icons.check_circle,
                        iconColor: AppColors.primary,
                        title: "Start ECG Recording",
                        message:
                        "Ensure your device is properly connected.\nDo you want to start the recording?",
                        textAlign: TextAlign.center,
                        buttonText1: "Yes",
                        buttonText2: "Cancel",
                        onButtonTap: () {
                          homeVM.goToBluetoothScanPage();
                        },
                        onButton2Tap: () {},
                      );
                    },
                    icon: SvgIcon(
                      AppAssets.rhythmBox,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Record ECG",
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "No ECG records available",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
  Widget _miniTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            // color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
            style:
            const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87// Regular
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
