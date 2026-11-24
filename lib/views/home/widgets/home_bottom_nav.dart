import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_color.dart';
import '../../../viewmodels/home_viewmodel.dart';

class HomeBottomNav extends GetView<HomeViewModel> {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => BottomNavigationBar(
      currentIndex: controller.currentIndex.value,
      onTap: controller.changeTab,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.video_call), label: 'Consultation'),
        BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Review'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      ],
    ));
  }
}
