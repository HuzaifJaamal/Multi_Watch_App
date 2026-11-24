import 'package:get/get.dart';
import '../core/storage/bluetooth_storage.dart';
import '../repositories/bluetooth_repository.dart';
import '../viewmodels/home_viewmodel.dart';


class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BluetoothStorage>(BluetoothStorage());

    Get.lazyPut<HomeViewModel>(
          () => HomeViewModel(
        deviceStorage: Get.find<BluetoothStorage>(),
        deviceDisconnect: Get.find<BluetoothRepository>(),
      ),
    );
  }
}
