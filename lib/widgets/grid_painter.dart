import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class GridPainter extends CustomPainter {
  final double cellSize;
  final int rows;
  final int cols;
  final img.Image image;
  final Color lineColor;
  final List<List<int>> rowHints;
  final List<List<int>> colHints;

  GridPainter({
    required this.cellSize,
    required this.image,
    required this.rows,
    required this.cols,
    required this.rowHints,
    required this.colHints,
    this.lineColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print('print-size: (${size.width} * ${size.height}), image-size: (${image.width} * ${image.height})');
    print('columns x rows: ${cols.toString()} * ${rows.toString()}');

    drawHints(canvas, cellSize);
    drawOutlines(canvas, size.width, size.height, cellSize);

  }

  void drawOutlines(Canvas canvas, double width, double height, double cellSize) {

    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3;
    double leftPadding = getHintsPadding(rowHints, cellSize).toDouble();
    double topPadding = getHintsPadding(colHints, cellSize).toDouble();
    // draw outline: top left corner -> top right corner
    canvas.drawLine(Offset(leftPadding, topPadding), Offset(width, topPadding), borderPaint);

    // draw outline: top left corner -> bottom left corner
    canvas.drawLine(Offset(leftPadding, topPadding), Offset(leftPadding, height), borderPaint);

    // draw outline: bottom left corner -> bottom right corner
    canvas.drawLine(Offset(leftPadding, height), Offset(width, height), borderPaint);

    // draw outline: top right corner -> bottom right corner
    canvas.drawLine(Offset(width, topPadding), Offset(width, height), borderPaint);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    // Draw vertical lines (columns)
    for (int c = 0; c <= cols; c++) {
      double x = c * cellSize;
      // draw outline: top -> bottom
      canvas.drawLine(
        Offset(x + leftPadding, topPadding),
        Offset(x + leftPadding, height),
        c % 5 == 0 ? borderPaint : paint,
      );
    }

    // Draw horizontal lines (rows)
    for (int r = 0; r <= rows; r++) {
      double y = r * cellSize;
      // draw outline: left -> right
      canvas.drawLine(
        Offset(leftPadding, y + topPadding),
        Offset(width, y + topPadding),
        r % 5 == 0 ? borderPaint : paint,
      );
    }
  }

  void drawHints(Canvas canvas, double cellSize) {
    double leftPadding = getHintsPadding(rowHints, cellSize).toDouble();
    double topPadding = getHintsPadding(colHints, cellSize).toDouble();
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final borderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3;

    // ✅ Draw row hints (left side)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int r = 0; r < rows; r++) {
      final hints = rowHints[r];
      for (int i = 0; i < hints.length; i++) {
        textPainter.text = TextSpan(
          text: hints[i].toString(),
          style: TextStyle(color: Colors.black, fontSize: cellSize * 0.6),
        );
        textPainter.layout(minWidth: cellSize, maxWidth: 30);
        textPainter.paint(
          canvas,
          Offset(leftPadding - (hints.length - i) * cellSize, (r * cellSize) + topPadding),
        );
      }

      double y = r * cellSize;
      canvas.drawLine(
        Offset(leftPadding, y + topPadding),
        Offset(leftPadding-((hints.length * cellSize) + 5), y + topPadding),
          r%5 == 0 ? borderPaint : paint,
      );
      canvas.drawLine(
        Offset(leftPadding, y + cellSize + topPadding),
        Offset(leftPadding-((hints.length * cellSize) + 5), y + cellSize + topPadding),
        (r+1)%5 == 0 ? borderPaint : paint,
      );
    }

    // ✅ Draw column hints (above)
    for (int c = 0; c < cols; c++) {
      final hints = colHints[c];
      for (int i = 0; i < hints.length; i++) {
        textPainter.text = TextSpan(
          text: hints[i].toString(),
          style: TextStyle(color: Colors.black, fontSize: cellSize * 0.6),
        );
        textPainter.layout(minWidth: cellSize, maxWidth: 30);
        textPainter.paint(
          canvas,
          Offset((c * cellSize) + leftPadding, topPadding - (hints.length - i) * cellSize),
        );
      }

      double x = c * cellSize;
      canvas.drawLine(
        Offset(x + leftPadding, topPadding),
        Offset(x + leftPadding, topPadding-((hints.length * cellSize) + 5)),
        c%5 == 0 ? borderPaint : paint,
      );
      canvas.drawLine(
        Offset(x + cellSize + leftPadding, topPadding),
        Offset(x + cellSize + leftPadding, topPadding-((hints.length * cellSize) + 5)),
          (c+1)%5 == 0 ? borderPaint : paint,
      );
    }
  }

  static num getHintsPadding(List<List<int>> hintList, cellSize) {
    int maxHints = 0;
    for (var hints in hintList) {
      maxHints = math.max(hints.length, maxHints);
    }
    return (maxHints * cellSize) + 5;
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return rows != oldDelegate.rows ||
        cols != oldDelegate.cols ||
        lineColor != oldDelegate.lineColor;
  }
}
