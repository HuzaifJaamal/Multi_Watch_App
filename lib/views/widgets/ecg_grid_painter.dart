import 'package:flutter/material.dart';

class EcgGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final small = Paint()
      ..color = Colors.green.withOpacity(0.15)
      ..strokeWidth = 0.5;

    final big = Paint()
      ..color = Colors.green.withOpacity(0.35)
      ..strokeWidth = 1;

    const mm = 4.0; // 1mm ≈ 4px (tune per device)

    for (double x = 0; x < size.width; x += mm) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          (x / mm) % 5 == 0 ? big : small);
    }

    for (double y = 0; y < size.height; y += mm) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          (y / mm) % 5 == 0 ? big : small);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
