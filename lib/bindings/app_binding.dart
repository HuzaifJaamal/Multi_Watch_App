import 'package:get/get.dart';
import '../core/storage/bluetooth_storage.dart';
import '../repositories/bluetooth_repository.dart';
import '../viewmodels/bluetooth_scan_viewmodel.dart';
import '../viewmodels/ekg_scan_setup_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BluetoothStorage>(
      BluetoothStorage(),
      permanent: true,
    );
    Get.put<LoginViewModel>(
      LoginViewModel(),
      permanent: true,
    );
    // 🔹 Repository (singleton)
    Get.put<BluetoothRepository>(
      BluetoothRepository.instance,
      permanent: true,
    );
    // 🔹 Scan ViewModel (singleton)
    Get.put<BluetoothScanViewModel>(
      BluetoothScanViewModel(Get.find()),
      permanent: true,
    );

    // 🔹 EKG Setup ViewModel
    Get.put<EkgScanSetupViewModel>(
      EkgScanSetupViewModel(
        Get.find<BluetoothRepository>(),
        Get.find<BluetoothStorage>(),
      ),
      permanent: true,
    );
  }
}



