import 'package:get/get.dart';
import '../data/ecg_stream_buffer.dart';
import '../repositories/bluetooth_repository.dart';
import '../repositories/ecg_export_repository.dart';
import '../repositories/record_repository.dart';
import '../viewmodels/ecg_export_viewmodel.dart';
import '../viewmodels/record_ekg_viewmodel.dart';
class RecordEkgBinding extends Bindings {
  @override
  void dependencies() {
    // 1️⃣ Register the stream buffer first
    Get.lazyPut<EcgStreamBuffer>(() => EcgStreamBuffer());

    // 2️⃣ Register the ECG repository using the buffer
    Get.lazyPut<EcgRepository>(() => EcgRepository(Get.find<EcgStreamBuffer>()));

    Get.lazyPut<EcgExportRepository>(
          () => EcgExportRepository(),
    );

    Get.lazyPut<EcgExportViewModel>(
          () => EcgExportViewModel(
        Get.find<EcgExportRepository>(),
      ),
    );


    // 4️⃣ Finally register the ViewModel
    Get.lazyPut<RecordEkgViewModel>(
          () => RecordEkgViewModel(
        Get.find<BluetoothRepository>(),
        Get.find<EcgRepository>(),
        Get.find<EcgExportViewModel>(),
      ),
    );
  }
}


