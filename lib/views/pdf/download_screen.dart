import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../viewmodels/ecg_export_viewmodel.dart';

class DownloadScreen extends GetView<EcgExportViewModel> {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Downloads")),

      body: Obx(() {
        if (controller.exports.isEmpty) {
          return const Center(child: Text("No downloads yet"));
        }

        return ListView.builder(
          itemCount: controller.exports.length,
          itemBuilder: (_, i) {
            final item = controller.exports[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text("ECG Report"),
                subtitle: Text(item.createdAt.toString()),
                trailing: const Icon(Icons.download),
                onTap: () {
                  // open PDF
                },
              ),
            );
          },
        );
      }),

      bottomNavigationBar: Obx(() {
        if (!controller.isGenerating.value) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 12),
              Text(controller.progressText.value),
            ],
          ),
        );
      }),
    );
  }
}
