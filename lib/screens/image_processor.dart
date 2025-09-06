import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:griddler_maker/widgets/ratio_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../widgets/grid_painter.dart';
import '../widgets/pixel_slider.dart';

class PixelateResult {
  final img.Image image;
  final List<List<List<double>>> debugMatrix;

  PixelateResult(this.image, this.debugMatrix);
}

class ImageProcessor extends StatefulWidget {
  @override
  _ImageProcessorState createState() => _ImageProcessorState();
}

class _ImageProcessorState extends State<ImageProcessor> {
  File? _imageFile;
  img.Image? _grayImage;
  PixelateResult? _pixilatedResult;
  double _pixelSize = 20; // default pixel size
  double _grayscaleLimit = 0.3; // default pixel size
  double _progress = 0.0;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _startProcessingImage() async {
    if (_imageFile != null) {
      setState(() {
        _loading = true;
      });
      _processImage(_imageFile!);
    }
  }

  void _processImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      // 1. Convert to grayscale (black & white)
      img.Image grayscale = img.grayscale(image);

      // 2. Pixelate
      PixelateResult pixelated = _pixelate(grayscale, _pixelSize.toInt());

      setState(() {
        _grayImage = grayscale;
        _pixilatedResult = pixelated;
        _loading = false;
      });
    }
  }

  PixelateResult _pixelate(img.Image src, int pixelSize) {
    print('_pixilate ${src.height} x ${src.width} to $pixelSize * $pixelSize');
    img.Image result = img.Image(width: pixelSize, height: pixelSize);
    int rangeY = ( src.height / pixelSize).round();
    int rangeX = ( src.width / pixelSize).round();

    print('any pixel will be $rangeX x $rangeY');

    List<List<List<double>>> debugMatrix = List.generate(
      pixelSize,
          (_) => List.filled(pixelSize, [0, 0]),
    );

    for (int y = 0; y < pixelSize; y++) {
      for (int x = 0; x < pixelSize; x++) {
        // In a pixel for the new image

        double pixelColorCombined = 0;
        for (int origY = y*rangeY; origY < math.min((y+1)*rangeY, src.height); origY++) {
          for (int origX = x*rangeX; origX < math.min((x+1)*rangeX, src.width); origX++) {
            if (y == 19 && origY == 957) {
              print('[#$y-$origY-$origX] running pixel');
            }
            // Take the color of the top-left pixel of the block
            img.Pixel pixel = src.getPixel(origX, origY);
            img.Color color = pixel.clone();
            // since it's grayscale, r == g == b

            try {
              num value = color.r / 255.0; // normalize to [0,1]
              pixelColorCombined += value;
            } catch (err) {
              num redColor = color.r;
              print('err on pixel [$origX, $origY] color of $redColor. err: $err');
            }
          }
        }

        final double avg = pixelColorCombined / (rangeX * rangeY);
        final double pixelColor = avg > _grayscaleLimit ? 255 : 0;
        result.setPixelRgb(x, y, pixelColor, pixelColor, pixelColor);
        debugMatrix[y][x] = [avg, pixelColorCombined];

        setState(() {
          // double shit = 1 / (pixelSize * pixelSize);
          // print('increase progress value $_progress by $shit');
          _progress += 1 / (pixelSize * pixelSize);
        });
      }
    }

    return PixelateResult(result, debugMatrix);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Pixelator")),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            _imageFile == null
            ? Text("Pick an image")
            : _loading
            ? LinearProgressIndicator(
                value: _progress,
                semanticsLabel: 'Processing Image...',
              )
            : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (_grayImage != null) {
                      return Image.memory(img.encodePng(img.copyResize(_grayImage!, width: (_pixelSize*10).floor(), height: (_pixelSize*10).floor())));
                    } else {
                      return Container();
                    }
                  }
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (_pixilatedResult != null) {
                      final PixelateResult pixilated = _pixilatedResult!;
                      final widgetImage =
                      Image.memory(img.encodePng(img.copyResize(pixilated.image, width: (_pixelSize*10).floor(), height: (_pixelSize*10).floor())));

                      final pixelSize = _pixelSize.toInt();
                      final rows =
                      (pixilated.image.height / pixelSize).ceil();
                      final cols =
                      (pixilated.image.width / pixelSize).ceil();

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          widgetImage, // the pixelated image
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                image: pixilated.image,
                                rows: rows,
                                cols: cols,
                                lineColor: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  }
                ),
                Expanded(
                    child: (_pixilatedResult != null) ? buildDebugTable(_pixilatedResult!.debugMatrix) : Container()
                ),
              ]
            ),
            SizedBox(height: 20),
            // Slider for pixel size
            PixelSlider(
              value: _pixelSize,
              onChanged: (val) {
                setState(() {
                  _pixelSize = val;
                });
              },
            ),
            RatioSlider(
                value: _grayscaleLimit,
                onChanged: (val) {
                  setState(() {
                    _grayscaleLimit = val;
                  });
                },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Choose Image"),
                ),
                ElevatedButton(
                  onPressed: _startProcessingImage,
                  child: Text("Generate"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _imageFile = null;
                      _grayImage = null;
                      _pixilatedResult = null;
                    });
                  },
                  child: Text("Reset"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildDebugTable(List<List<List<double>>> matrix) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: matrix.map((row) {
        return Row(
          children: row.map((cell) {
            // Convert the double list into a readable string
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