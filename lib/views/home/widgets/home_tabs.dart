import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../viewmodels/home_viewmodel.dart';
import '../tabs/chat_tab.dart';
import '../tabs/consultation_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/home_tab.dart';
import '../tabs/review_tab.dart';

class HomeTabs extends GetView<HomeViewModel> {
  const HomeTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => IndexedStack(
      index: controller.currentIndex.value,
      children: const [
        HomeTab(),
        ConsultationTab(),
        ReviewTab(),
        ChatTab(),
        HistoryTab(),
      ],
    ));
  }
}
