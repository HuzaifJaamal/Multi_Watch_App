// ******************************************************************************************
// COMPLETE PORTRAIT ECG EXPORTER (FINAL VERSION)
// Fully functional – JSON → PNG → PORTRAIT PDF (your exact required layout)
// ******************************************************************************************

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../models/ecg_pdf_model.dart';
import '../isolate/ecg_pdf_isolate.dart';

class EcgExportPortraitFinal {

  // ==========================================================================================
  // 1) DRAW PNG WAVEFORM (OFFSCREEN CANVAS)
  // ==========================================================================================
  static Future<Uint8List> drawWaveformToPng(
      List<int> samples, {
        required int width,
        required int height,
      }) async {

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // BACKGROUND WHITE
    final bgPaint = ui.Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    // ============================
    //  ECG GRID DRAWING
    // ============================
    const double smallGrid = 9.6;   // 0.5mm in your scale
    const int majorEvery = 5;        // 5 small boxes = bold line

    final smallLine = ui.Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    final majorLine = ui.Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;


 // Vertical grid lines
    for (double x = 0; x <= width; x += smallGrid) {
      int idx = (x / smallGrid).round();
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height.toDouble()),
        idx % majorEvery == 0 ? majorLine : smallLine,
      );
    }

    // Horizontal grid lines
    for (double y = 0; y <= height; y += smallGrid) {
      int idx = ((y / smallGrid)).round();
      canvas.drawLine(
        Offset(0, y),
        Offset(width.toDouble(), y),
        idx % majorEvery == 0 ? majorLine : smallLine,
      );
    }

    // ============================
    //  DRAW WAVEFORM
    // ============================
    if (samples.length < 2) {
      final img = await recorder.endRecording().toImage(width, height);
      final b = await img.toByteData(format: ui.ImageByteFormat.png);
      return b!.buffer.asUint8List();
    }

    // Downsample
    int factor = (samples.length / width).ceil();
    if (factor < 1) factor = 1;

    List<double> pts = [];
    for (int i = 0; i < samples.length; i += factor) {
      pts.add(samples[i].toDouble());
    }

    // Normalize amplitude
    final minV = pts.reduce(math.min);
    final maxV = pts.reduce(math.max);
    final mid = (minV + maxV) / 2;
    final diff = ((maxV - minV) / 2).abs() == 0 ? 1 : (maxV - minV) / 2;

    final scale = (height * 0.20) / diff;
    final centerY = height / 2;

    final wavePaint = ui.Paint()
      ..color = Colors.black
      ..strokeWidth = 5
      ..style = ui.PaintingStyle.stroke;

    final path = ui.Path();
    for (int i = 0; i < pts.length; i++) {
      double x = (i / (pts.length - 1)) * (width - 1);
      double y = centerY - ((pts[i] - mid) * scale);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }

    canvas.drawPath(path, wavePaint);

    // EXPORT
    final img = await recorder.endRecording().toImage(width, height);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    return b!.buffer.asUint8List();
  }


  // ==========================================================================================
  // 2) SEGMENT LEADS + DRAW PNGS
  // ==========================================================================================
  static Future<Map<String, Uint8List>> generatePngs(
      Map<String, List<int>> leads, {
        int sampleRate = 250,
        int segmentSeconds = 5,
        int width = 1200,
        int height = 385,
      }) async {
    final out = <String, Uint8List>{};

    for (final entry in leads.entries) {
      final lead = entry.key;
      final samples = entry.value;

      int perSeg = sampleRate * segmentSeconds;
      int segments = (samples.length / perSeg).ceil();

      for (int s = 0; s < segments; s++) {
        int start = s * perSeg;
        int end = math.min(start + perSeg, samples.length);
        final chunk = samples.sublist(start, end);

        out["${lead}_$s"] = await drawWaveformToPng(
          chunk,
          width: width,
          height: height,
        );
        await Future.delayed(const Duration(milliseconds: 264));
      }
    }

    return out;
  }


  // ==========================================================================================
  // 3) FULL PORTRAIT PDF (YOUR EXACT LAYOUT)
  // ==========================================================================================
  static Future<String> generatePdfPortrait({
    required Map<String, Uint8List> pngs,
    required int hr,
    required int qt,
    required int hrv,
    required int segmentSeconds,
    required EcgPdfModel review, // ✅ ADD THIS
    String diagnosis = "",
    String filePrefix = "ecg_portrait",
  }) async {

    final doc = PdfDocument();
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final labelFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold);
    final valueFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    final gridLabelFornt = PdfStandardFont(PdfFontFamily.helvetica, 6);


    PdfPage addPage() {
      // Age from DOB
      final dob = DateTime.fromMillisecondsSinceEpoch(review.heartRate);
      final age = DateTime.now().year - dob.year;
      final p = doc.pages.add();
      _drawHeaderPdf(
        p,
        titleFont,
        labelFont,
        valueFont,
        hr,
        qt,
        hrv,
        age,
        diagnosis,
        review, // ✅ PASS HERE
      );
      return p;
    }

    PdfPage page = addPage();
    final pageW = page.getClientSize().width;
    final pageH = page.getClientSize().height;

    double y = 100; // content start below header

    // Tighter layout
    const double rowHeight = 90; // was 130
    const double rowGap = 5;     // was 10

    // lead pairing
    final pairs = [
      ["I", "aVR"],
      ["II", "aVL"],
      ["III", "aVF"],
    ];

    // detect segments from keys like "I_0", "II_1", etc.
    final segments = <int>{};
    for (final k in pngs.keys) {
      if (!k.contains("_")) continue;
      final segStr = k.split("_").last;
      final seg = int.tryParse(segStr);
      if (seg != null) segments.add(seg);
    }
    final orderedSeg = segments.toList()..sort();

    int blocksOnPage = 0;

    for (final seg in orderedSeg) {
      // If already 2 blocks drawn on this page → move to new page
      if (blocksOnPage == 2) {
        page = addPage();
        y = 100;
        blocksOnPage = 0;
        await Future.delayed(const Duration(milliseconds: 264));
      }

      final start = seg * segmentSeconds;
      final end = start + segmentSeconds;

      y += 20;

      // 3 lead rows
      for (var p in pairs) {
        final leftKey = "${p[0]}_$seg";
        final rightKey = "${p[1]}_$seg";

        if (!pngs.containsKey(leftKey) || !pngs.containsKey(rightKey)) {
          y += rowHeight + rowGap;
          continue;
        }

        final leftBmp = PdfBitmap(pngs[leftKey]!);
        final rightBmp = PdfBitmap(pngs[rightKey]!);


        // Left waveform (I / II / III)
        page.graphics.drawImage(
          leftBmp,
          Rect.fromLTWH(
            20,
            y,
            (pageW / 2) - 12,
            rowHeight,
          ),
        );

        // Draw vertical separator line
        final double middleX = pageW / 2;
        final PdfPen pen = PdfPen(PdfColor(128, 128, 128), width: 2.45); // Black line, width 1
        page.graphics.drawLine(
          pen,
          Offset(middleX + 9.25, y),
          Offset(middleX + 9.25, y + rowHeight + 5.3),
        );


        // Right waveform (aVR / aVL / aVF)
        page.graphics.drawImage(
          rightBmp,
          Rect.fromLTWH(
            (pageW / 2) + 10.5,
            y ,
            (pageW / 2) - 15,
            rowHeight,
          ),
        );


        // Lead labels
        page.graphics.drawString(
          p[0],
          valueFont,
          bounds: Rect.fromLTWH(25, y + 4, 50, 16),
        );
        page.graphics.drawString(
          p[1],
          valueFont,
          bounds: Rect.fromLTWH((pageW / 2) + 15, y + 4, 50, 16),
        );

        // =======================
        // Seconds only for III/aVF
        // =======================
        if (p[0] == "III") {
          final int segStart = seg * segmentSeconds;      // e.g. 0, 5, 10...
          final int segEnd   = segStart + segmentSeconds; // e.g. 5, 10, 15...

// total "positions" you want (including the hidden last one)
          final int nPositions = segEnd - segStart + 1;   // e.g. 0..5 → 6 positions

          final double leftWidth  = 49;
          final double rightWidth = 48.5;
          final double labelY = y + 88.5 ;
          // print("label-Y: $labelY");

          // ----- LEFT (III) -----
          for (int i = 0; i < nPositions; i++) {

            final double x = 19.5 + leftWidth  * i;

            final int t = segStart + i;

            // skip the last one (5, 10, 15, ...)
            if (i == nPositions - 1) {
              page.graphics.drawString(
                "|",
                gridLabelFornt,
                brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
                bounds: Rect.fromLTWH(x - 0.03, labelY, 30, 12),
              );
              continue; // keep the space, but don't draw any number
            }

            page.graphics.drawString(
              "|",
              gridLabelFornt,
              brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
              bounds: Rect.fromLTWH(x, labelY, 30, 12),
            );
            page.graphics.drawString(
              " ${t}s",
              gridLabelFornt,
              brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
              bounds: Rect.fromLTWH(x, labelY + 1, 30, 12),
            );
          }


          // ----- RIGHT (aVF) -----
          for (int i = 0; i < nPositions; i++) {
            final double x = (pageW / 2) + 9.8 + rightWidth * i;
            // print("x Value: $x");
            final int t = segStart + i;

            if (i == nPositions - 1) {
              page.graphics.drawString(
                "|",
                gridLabelFornt,
                brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
                bounds: Rect.fromLTWH(x - 0.3, labelY, 30, 12),
              );
              continue; // same: no label at the last tick
            }

            page.graphics.drawString(
              "|",
              gridLabelFornt,
              brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
              bounds: Rect.fromLTWH(x, labelY, 30, 12),
            );
            page.graphics.drawString(
              " ${t}s",
              gridLabelFornt,
              brush: PdfSolidBrush(PdfColor(75, 75, 75)), // RGB
              bounds: Rect.fromLTWH(x, labelY + 1, 30, 12),
            );
          }

        }
        y += rowHeight;
      }
      // One block finished
      blocksOnPage++;
      // Small extra gap between blocks (on same page)
      y += 10;
    }
    // Footer pagination
    int totalPages = doc.pages.count;
    for (int i = 0; i < totalPages; i++) {
      final PdfPage p = doc.pages[i];

      p.graphics.drawString(
        "Report generated from device-captured ECG data",
        valueFont,
        bounds: Rect.fromLTWH(22, pageH - 30, 280, 12),
      );

      p.graphics.drawString(
        "Page ${i + 1} of $totalPages",
        valueFont,
        bounds: Rect.fromLTWH(pageW - 110, pageH - 30, 100, 12),
      );
    }

    final bytes = await doc.save();
    doc.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = "${dir.path}/${filePrefix}_$ts.pdf";

    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }


  // ==========================================================================================
  // 4) HEADER
  // ==========================================================================================

  static void _drawHeaderPdf(
      PdfPage page,
      PdfFont titleFont,
      PdfFont labelFont,
      PdfFont valueFont,
      int hr,
      int qt,
      int hrv,
      int age,
      String diagnosis,
      EcgPdfModel review, // ✅ ADD
      ) {
    final now = DateTime.now();
    late final dateStr = DateFormat('yyyy-MM-dd').format(now);
    late final timeStr = DateFormat('HH:mm:ss').format(now);

    page.graphics.drawString(
      "ECG Recording Report",
      // headerText,
      titleFont,
      // valueFont,
      bounds: Rect.fromLTWH(170, 5, 200, 20),
    );
    page.graphics.drawString(
      "_______________________________________________________________________________________________",
      valueFont,
      bounds: const Rect.fromLTWH(0, 20, 0, 0),
    );
    page.graphics.drawString("Name:", labelFont,
        bounds: const Rect.fromLTWH(22, 24 + 28, 200, 12));
    page.graphics.drawString(
      "Admin",
      valueFont,
      bounds: const Rect.fromLTWH(22 + 30, 24 + 28, 200, 12),
    );

    page.graphics.drawString("Age:", labelFont,
        bounds: const Rect.fromLTWH(22 , 24 + 40, 200, 12));

    page.graphics.drawString(
        "$age Years",
        valueFont,
        bounds: const Rect.fromLTWH(22 + 25, 24 + 40, 200, 12));

    page.graphics.drawString("Date:", labelFont,
        bounds: const Rect.fromLTWH(22 + 380, 24 + 28, 200, 12));
    page.graphics.drawString(
      dateStr,
      valueFont,
      bounds: const Rect.fromLTWH(22 + 410, 24 + 28, 200, 12),
    );

    page.graphics.drawString("Time:", labelFont,
        bounds: const Rect.fromLTWH(22 + 380, 24 + 40, 200, 12));

    page.graphics.drawString(timeStr, valueFont,
        bounds: const Rect.fromLTWH(22 + 410, 24 + 40, 200, 12));

    page.graphics.drawString("Gender:", labelFont,
        bounds: const Rect.fromLTWH(22, 24 + 60, 200, 12));
    page.graphics.drawString(
        "Male",
        // " ${review.patientGender}",
        valueFont,
        bounds: const Rect.fromLTWH(22 +40, 24 + 60, 200, 12));

    /*page.graphics.drawString("HR:", labelFont,
        bounds: const Rect.fromLTWH(22, 24 + 60, 200, 12));
    page.graphics.drawString("$hr BPM", valueFont,
        bounds: const Rect.fromLTWH(22 +20, 24 + 60, 200, 12));*/

    page.graphics.drawString("Rhythm:", labelFont,
        bounds: const Rect.fromLTWH(22 + 185, 24 + 60, 200, 12));
    page.graphics.drawString(
        "${review.diagnosis}",
        // "$qt ms",
        valueFont,
        bounds:const Rect.fromLTWH(22 + 230, 24 + 60, 200, 12));

    /*page.graphics.drawString("QT:", labelFont,
        bounds: const Rect.fromLTWH(22 + 200, 24 + 60, 200, 12));
    page.graphics.drawString("$qt ms", valueFont,
        bounds:const Rect.fromLTWH(22 + 220, 24 + 60, 200, 12));*/

    page.graphics.drawString("HR:", labelFont,
        bounds: const Rect.fromLTWH(22 + 380, 24 + 60, 200, 12));
    page.graphics.drawString("${review.heartRate} BPM", valueFont,
        bounds:const Rect.fromLTWH(22 + 400, 24 + 60, 200, 12));
  }


  // ==========================================================================================
  // 5) FULL END-TO-END WRAPPER: JSON → PNG → PORTRAIT PDF
  // ==========================================================================================

  static Future<String> generateFromJsonSafe(String jsonPath, EcgPdfModel review,) async {
    // Parse heart rate, QT, HRV, diagnosis on main isolate
    final raw = await File(jsonPath).readAsString();
    final jsonData = jsonDecode(raw);

    final hr = jsonData["heartRate"] ?? 0;
    final qt = jsonData["qt"] ?? 0;
    final hrv = jsonData["hrv"] ?? 0;
    final diagnosis = jsonData["diagnosis"] ?? "";
    final segmentSeconds = 5;

    // Step 1: Process leads in background isolate
    final processedLeads = await compute(processLeadsInIsolate, jsonPath);

    // Step 2: Draw PNGs on main isolate (UI thread)
    final pngs = await EcgExportPortraitFinal.generatePngs(
      processedLeads.map((k, v) => MapEntry(k, v.map((d) => d.toInt()).toList())),
      sampleRate: 250,
      segmentSeconds: segmentSeconds,
      width: 1200,
      height: 385,
    );

    // Step 3: Generate final PDF on main isolate
    return EcgExportPortraitFinal.generatePdfPortrait(
      pngs: pngs,
      hr: hr,
      qt: qt,
      hrv: hrv,
      diagnosis: diagnosis,
      segmentSeconds: segmentSeconds,
      review: review, // ✅ ADD THIS
    );
  }

}
