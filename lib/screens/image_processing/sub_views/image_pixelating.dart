import 'package:flutter/material.dart';
import 'package:griddler_maker/models/pixelate_result.dart';
import 'package:griddler_maker/screens/image_processing/layout.dart';
import 'package:image/image.dart' as img;

import '../../../widgets/grid_painter.dart';
import '../components/pixel_sliders.dart';

class ImagePixelating extends StatelessWidget {
  final img.Image? baseImage;
  final PixelateResult? pixelatedResult;
  final int width;
  final int height;
  final int resize;
  final double crossover;
  final void Function(PixelateResult, double) pixelateFunction;

  const ImagePixelating({
    super.key,
    required this.baseImage,
    required this.pixelatedResult,
    required this.width,
    required this.height,
    required this.resize,
    required this.crossover,
    required this.pixelateFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Layout(
      mainArea: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
              child: (pixelatedResult != null) ? buildDebugTable(pixelatedResult!.debugMatrix, crossover) : Container()
          ),
          baseImage == null
              ? Text("Pick an Image")
              : RepaintBoundary(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (pixelatedResult != null) {
                    final PixelateResult pixelated = pixelatedResult!;
                    print('width: $width => ${width*resize} height: $height => ${height*resize}');
                    final widgetImage =
                    Image.memory(img.encodePng(img.copyResize(pixelated.image, width: (width*resize), height: (width*resize))));

                    return Stack(
                      alignment: Alignment.bottomLeft,
                      children: [
                        widgetImage, // the pixelated image
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(
                              image: pixelated.image,
                              cellSize: resize.toDouble(),
                              rowHints: [],
                              colHints: [],
                              rows: height,
                              cols: width,
                              lineColor: Colors.black,
                            )
                          ),
                        ),
                      ]
                    );
                  } else {
                    return Container();
                  }
                }
              )
            ),
        ],
      ),
      secondaryArea: Column(
        children: [
          PixelSliders(
            image: baseImage!,
            onSettingChange: pixelateFunction,
          ),
        ],
      ),
    );
  }
}

Widget buildDebugTable(List<List<List<double>>> matrix, double grayscaleLimit) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matrix.asMap().entries.map((rowEntry) {
        return Row(
          children: rowEntry.value.asMap().entries.map((cellEntry) {
            // Convert the double list into a readable string
            List<double> cell = cellEntry.value;
            final value = cell.map((v) => v.toStringAsFixed(2)).join(", ");

            try {
              Color((cell[0] * 255).floor());
            } catch (err) {
              double val = cell[0];
              print('err on color cell[0] $val. err: $err');
            }

            // Safely convert to color
            final color = Color.fromRGBO(
              (cell[0] * 255).clamp(0, 255).toInt(),
              (cell.length > 1 ? (cell[1] * 255).clamp(0, 255).toInt() : 0),
              (cell.length > 2 ? (cell[2] * 255).clamp(0, 255).toInt() : 0),
              1,
            );

            return Tooltip(
              message: value, // show on hover
              waitDuration: const Duration(milliseconds: 300),
              child: Container(
                child: Text((cellEntry.key + (matrix.length*rowEntry.key)).toString(), style: TextStyle(fontSize: 8, fontWeight: cell[0] < grayscaleLimit ? FontWeight.w800 : FontWeight.normal)),
                width: 24,
                height: 24,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: color, // Color((cell[0] * 255).floor()),
                  border: Border.all(color: Colors.black26),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    ),
  );
}