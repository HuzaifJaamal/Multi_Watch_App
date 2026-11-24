import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String pdfPath;

  const PdfPreviewScreen({
    super.key,
    required this.pdfPath,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(pdfPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ECG PDF Preview"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Share.shareXFiles(
                [XFile(file.path)],
                text: "ECG Report PDF",
              );
            },
          ),
        ],
      ),

      body: SfPdfViewer.file(
        file,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}
