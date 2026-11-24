import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_color.dart';
import '../core/widgets/svg_icon.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginViewModel vm =
  Get.put(LoginViewModel());

  final GlobalKey _errorKey = GlobalKey(); // ✅ persistent
  @override
  void initState() {
    super.initState();

    ever(vm.errorMessage, (msg) {
      if (msg.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_errorKey.currentContext != null) {
            Scrollable.ensureVisible(
              _errorKey.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {


    return WillPopScope(
      onWillPop: () async {
        // 🔥 If keyboard is open → close it
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          FocusScope.of(context).unfocus();
          return false; // ⛔ DO NOT EXIT APP
        }

        // 🔒 Prevent back while loading
        if (vm.isLoading.value) return false;

        return true; // ✅ Allow app exit
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildBody(),
      ),
    );
  }
  Widget _buildBody() {
    return Stack(
      children: [

        /// 🔹 MAIN CONTENT
        Obx(() => AbsorbPointer(
          absorbing: vm.isLoading.value, // 🔒 block taps
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                /// LOGO
                SvgIcon(
                  AppAssets.logo,
                  size: 28,
                  color: AppColors.primary,
                ),

                const SizedBox(height: 20),

                /// WELCOME TEXT
                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 6),
                const Text("Please enter credentials below"),

                const SizedBox(height: 30),

                /// BOTTOM CARD (MATCHES OLD UI)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      boxShadow: [
                        // Main soft shadow
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.12),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, -6),
                        ),

                        // Secondary lighter shadow for depth
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(overscroll: false),
                      child: SingleChildScrollView(

                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          30,
                          20,
                          MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// SIGN IN TITLE
                            const Center(
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                "Enter your phone number and password",
                              ),
                            ),

                            const SizedBox(height: 24),
                            /// PHONE
                            _label("Phone Number"),
                            _input(
                              controller:  vm.phoneCtrl,
                              focusNode: vm.phoneFocus,
                              nextFocus: vm.passwordFocus,
                              hint: "Enter your number",
                              keyboard: TextInputType.phone,
                              prefixIcon: Icons.call,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  // Allow empty (user deleting)
                                  if (newValue.text.isEmpty) return newValue;

                                  // Must start with 0
                                  if (!newValue.text.startsWith('0')) {
                                    return oldValue;
                                  }
                                  if (newValue.text.length >= 2 &&
                                      !newValue.text.startsWith('03')) {
                                    return oldValue;
                                  }

                                  return newValue;
                                }),
                              ],
                            ),


                            const SizedBox(height: 16),
                            _label("Password"),
                            Obx(() => _input(
                              controller: vm.passwordCtrl,
                              focusNode: vm.passwordFocus,
                              hint: "Enter your password",
                              obscure: vm.isHidePassword.value,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                iconSize: 18,
                                icon: Icon(
                                  vm.isHidePassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primary,
                                ),
                                onPressed: vm.toggleHidePassword,
                              ),
                            )),



                            const SizedBox(height: 12),

                            /// ERROR MESSAGE
                            Obx(() => vm.errorMessage.value.isNotEmpty
                                ? Text(
                              vm.errorMessage.value,
                              key: _errorKey,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 14,
                                ),
                              )
                                : const SizedBox()),


                            const SizedBox(height: 20),

                            /// BUTTON
                            Obx(() => SizedBox(
                              width: double.infinity,
                              height: 52,
                              child:
                              ElevatedButton(
                                onPressed: vm.isLoading.value
                                    ? null
                                    : () => vm.login(
                                  phone: vm.phoneCtrl.text,
                                  password: vm.passwordCtrl.text,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: vm.isLoading.value
                                      ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.whiteGhost,
                                        ),
                                  )
                                    : Row(
                                      mainAxisSize: MainAxisSize.min, // 🔑 prevents full-width overflow
                                      children: [
                                        Text(
                                          "Continue",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: AppColors.whiteGhost,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: AppColors.whiteGhost,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),

                            )),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )),

        /// 🔹 FULL SCREEN LOADER
        Obx(() {
          if (!vm.isLoading.value) return const SizedBox();

          return Container(
            color: AppColors.black.withOpacity(0.35), // 🔥 dim background
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 140,
                    child: Lottie.asset("assets/lottie/loading.json", repeat: true),
                  ),
                  SizedBox(height: 12),
                  Text("Logging Please wait...",
                      style: TextStyle(color: AppColors.whiteGhost,)),
                ],
              )
            ),
          );
        }),
      ],
    );
  }


  /// ---------- UI HELPERS ----------

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    bool enabled = true,
    IconData? prefixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboard,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      // ✅ KEYBOARD ACTION
      textInputAction:
      nextFocus != null ? TextInputAction.next : TextInputAction.done,

      // ✅ MOVE FOCUS
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary)
            : null,
        suffixIcon: suffixIcon,
        filled: true,

        // 🟢 Default border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey,
            width: 1,
          ),
        ),

        // 🔵 Focused border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        // 🔴 Error border (optional future-proofing)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.red,
            width: 1,
          ),
        ),

        // 🔴 Focused error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.red,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
