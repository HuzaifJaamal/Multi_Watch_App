import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_color.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_tabs.dart';

class HomeScreen extends GetView<HomeViewModel> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteGhost,
      bottomNavigationBar: const HomeBottomNav(),
      body: const HomeTabs(),
    );
  }
}

