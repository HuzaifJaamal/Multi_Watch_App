import '../core/utils/_ecg_export_helper.dart';
import '../models/ecg_pdf_model.dart';

class EcgExportRepository {

  Future<String> generate(String jsonPath, EcgPdfModel review) async {
    return EcgExportPortraitFinal.generateFromJsonSafe(jsonPath, review);
  }
}


