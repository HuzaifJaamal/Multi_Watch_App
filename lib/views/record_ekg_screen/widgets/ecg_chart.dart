import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_color.dart';

class ChartConfig {
  static FlGridData buildGridData({
    required double verticalInterval,
    required double horizontalInterval,
  }) {
    return FlGridData(
      show: true,
      drawHorizontalLine: true,
      drawVerticalLine: true,
      horizontalInterval: horizontalInterval,
      verticalInterval: verticalInterval,
      getDrawingHorizontalLine: (value) {
        int index = (value / horizontalInterval).round();
        return FlLine(
          color: index % 5 == 0 ? AppColors.greyLargeLine : AppColors.greySmallLine,
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        int index = (value / verticalInterval).round();
        return FlLine(
          color: index % 5 == 0 ? AppColors.greyLargeLine : AppColors.greySmallLine,
          strokeWidth: 1,
        );
      },
      checkToShowVerticalLine: (value) => true,
      checkToShowHorizontalLine: (value) => true,
    );
  }

  static FlBorderData getBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: AppColors.greyLargeLine, width: 1),
    );
  }

  static FlTitlesData getTitlesData() {
    return FlTitlesData(show: false);
  }
}
