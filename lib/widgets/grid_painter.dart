import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final img.Image image;
  final Color lineColor;

  GridPainter({
    required this.image,
    required this.rows,
    required this.cols,
    this.lineColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print(size);
    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), borderPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), borderPaint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), borderPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), borderPaint);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    double cellWidth = size.width / cols;
    double cellHeight = size.height / rows;

    // Draw vertical lines
    for (int c = 0; c <= image.height; c++) {
      double x = c * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int r = 0; r <= image.width; r++) {
      double y = r * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return rows != oldDelegate.rows ||
        cols != oldDelegate.cols ||
        lineColor != oldDelegate.lineColor;
  }
}
