import 'package:flutter/material.dart';
import '../../../core/constants/app_color.dart';
import '../../../models/ecg_data_point.dart';
import '../../widgets/ecg_grid_painter.dart';

import 'ecg_real_time_painter.dart'; // for ChartConfig


/// Builds the container with the ECG chart for one lead

Widget buildLeadChart(
    BuildContext context,
    String lead,
    List<EcgDataPoint> data,
    int writeIndex,

    ) {
  final height = MediaQuery.of(context).size.height * 0.11;

  return Container(
    height: height,
    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black,
      border: Border.all(color: Colors.green.shade700),
    ),
    child:
    Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: EcgGridPainter(),
        ),
        Text("Lead $lead",
            style: const TextStyle(fontWeight: FontWeight.bold,color: AppColors.whiteGhost)),
        RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: EcgRealTimePainter(
              data,
              writeIndex,
            ),
          ),
        ),
      ],
    )
  );
}


