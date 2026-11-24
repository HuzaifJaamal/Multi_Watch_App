import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_color.dart';

void showSnackBarError(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.isSnackbarOpen == false) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.red,
        colorText: AppColors.whiteGhost,
        borderRadius: 8,
      );
    }
  });
}

void showSnackBarSuccess(String title, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.isSnackbarOpen == false) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
        colorText: AppColors.whiteGhost,
        borderRadius: 8,
      );
    }
  });
}