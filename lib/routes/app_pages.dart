import 'package:get/get_navigation/src/routes/get_route.dart';
import '../bindings/app_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/record_ekg_binding.dart';
import '../views/bluetooth/BluetoothScanAnimatedScreen.dart';
import '../views/ekg_scan_setup.dart';
import '../views/home/home_screen.dart';
import '../views/login_screen.dart';
import '../views/record_ekg_screen/record_ekg_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.login, page: () => LoginScreen()),

    GetPage(
        name: AppRoutes.home,
        page: () => HomeScreen(),
        binding: HomeBinding(), // ✅ Add this
    ),
    GetPage(
      name: AppRoutes.bluetoothScanPage,
      page: () => BluetoothScanAnimatedScreen(),
      binding: AppBinding(), // ✅ Add this
    ),
    GetPage(
      name: AppRoutes.ekgSetup,
      page: () => EkgScanSetupScreen(),
      binding: AppBinding(),
    ),
    GetPage(
      name: AppRoutes.recordScreen,
      page: () => RecordEkgScreen(),
      binding: RecordEkgBinding(),
    ),
  ];
}
