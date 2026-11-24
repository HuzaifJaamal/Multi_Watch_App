import 'package:get/get.dart';

import '../core/services/connectivity_service.dart';
import '../core/snack_bar/snack_bar_error.dart';

import '../models/user_model.dart';

import 'package:flutter/material.dart';

class LoginViewModel extends GetxController {

  final ConnectivityService connectivity = Get.find();


  var isLoading = false.obs;
  Rxn<UserModel> user = Rxn<UserModel>();
  var token = "".obs;
  var errorMessage = "".obs;

  final isHidePassword = true.obs;


  late TextEditingController phoneCtrl;
  late TextEditingController passwordCtrl;

  late FocusNode phoneFocus;
  late FocusNode passwordFocus;


  @override
  void onInit() {
    super.onInit();

    phoneCtrl = TextEditingController(text: "03001234567");
    passwordCtrl = TextEditingController(text: "123456");

    phoneFocus = FocusNode();
    passwordFocus = FocusNode();

    phoneFocus.addListener(_onFocusChange);
    passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (errorMessage.isNotEmpty) {
      errorMessage.value = '';
    }
  }
  void clearError() {
    errorMessage.value = "";
  }

  void toggleHidePassword() {
    isHidePassword.value = !isHidePassword.value;
  }

  void fieldClear() {
    phoneCtrl.clear();
    passwordCtrl.clear();

  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Hardcoded credentials
      const validPhone = "03001234567";
      const validPassword = "123456";

      if (phone == validPhone && password == validPassword) {
        showSnackBarSuccess(
          "Login Success 👏",
          "Welcome Admin",
        );

        await Future.delayed(const Duration(seconds: 1));

        Get.offAllNamed('/home');

        fieldClear();
      } else {
        errorMessage.value = "Invalid phone number or password";
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

}




