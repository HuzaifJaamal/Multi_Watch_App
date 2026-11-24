import 'package:flutter/material.dart';
import '../../../models/ecg_data_point.dart';


class EcgRealTimePainter extends CustomPainter {
  final List<EcgDataPoint> data;
  final int writeIndex;

  EcgRealTimePainter(this.data, this.writeIndex);
  @override
  void paint(Canvas canvas, Size size) {
    final bufferSize = data.length;
    final dx = size.width / bufferSize;
    final midY = size.height / 2;

    // CLEAR AHEAD OF CURSOR
    final cursorX = (writeIndex % bufferSize) * dx;
    canvas.drawRect(
      Rect.fromLTWH(cursorX, 0, dx * 3, size.height),
      Paint()
        ..blendMode = BlendMode.clear,
    );

    final paint = Paint()
      ..color = Colors.green.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    Path path = Path();
    bool started = false;
// Compute oldest sample index in circular buffer
    final oldestIndex = writeIndex % data.length;
    for (int i = 0; i < bufferSize; i++) {
      final value = data[i].value;

      if (value.isNaN) {
        if (started) {
          canvas.drawPath(path, paint);
          path = Path();
          started = false;
        }
        continue;
      }
      // 👇 wrap x index at 1000
      final drawIndex = i % 1000;

      final x = drawIndex * dx;
      double y = midY - (value * 0.004);
      y = y.clamp(0.0, size.height);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    if (started) {
      canvas.drawPath(path, paint);
    }

    // Optional cursor line
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, size.height),
      Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant EcgRealTimePainter oldDelegate) => true;
}




