import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ecg_pdf_model.dart';
import '../repositories/ecg_export_repository.dart';
import '../models/ecg_export_item.dart';

class EcgExportViewModel extends GetxController {
  final EcgExportRepository repo;
  EcgExportViewModel(this.repo);

  final isGenerating = false.obs;
  final progressText = "".obs;

  /// Download screen list
  final exports = <EcgExportItem>[].obs;

  /// 🆕 indicates last generation finished
  final hasGenerated = false.obs;

   String? lastGeneratedPath;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> generatePdf(String jsonPath, EcgPdfModel review) async {
    try {
      isGenerating.value = true;
      hasGenerated.value = false;
      progressText.value = "Preparing ECG data...";

      // Yield to UI before heavy work
      await Future.delayed(const Duration(milliseconds: 128));

      progressText.value = "Rendering ECG waveforms...";
      final path = await repo.generate(jsonPath, review);
      lastGeneratedPath = path;
      // Yield again before UI update
      await Future.delayed(const Duration(milliseconds: 64));

      exports.insert(
        0,
        EcgExportItem(
          path: path,
          createdAt: DateTime.now(),
        ),
      );
      hasGenerated.value = true; // ✅ PDF ready
      progressText.value = "ECG PDF generated successfully";
    } catch (e, st) {
      progressText.value = "Failed to generate ECG PDF";
      debugPrint("ECG PDF error: $e");
      debugPrintStack(stackTrace: st);
      rethrow;
    } finally {
      // Small delay so user sees success text
      await Future.delayed(const Duration(milliseconds: 400));
      isGenerating.value = false;
      progressText.value = "";
    }
  }

}
