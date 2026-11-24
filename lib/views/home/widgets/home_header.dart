import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_color.dart';
import '../../../core/dialogs/custom_dialog.dart';
import '../../../viewmodels/home_viewmodel.dart';

class HomeHeader extends GetView<HomeViewModel> {

  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.grey,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Obx(() {
          final user = controller.user.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome,", style: TextStyle(color: AppColors.primary)),
              Text(
                user?.fullName ?? 'Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          );
        }),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
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
                await controller.logout(); // 🔑 CALL the method
              },

              /// ❌ CANCEL ACTION
              onButton2Tap: () {
                Get.back(); // just close dialog
              },
            );
          },
        ),
      ],
    );
  }
}
