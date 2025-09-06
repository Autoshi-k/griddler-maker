import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:griddler_maker/widgets/ratio_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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
  int _pixelSize = 20; // default pixel size
  int _pixelImageHeight = 20;
  final int _resize = 20;
  final GlobalKey _puzzleKey = GlobalKey();


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

  // Future<Uint8List> capturePuzzle(GlobalKey key) async {
  //   RenderRepaintBoundary boundary =
  //   key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  //   ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  //   ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  //   return byteData!.buffer.asUint8List();
  // }

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
      PixelateResult pixelated = _pixelate(grayscale, _pixelSize);

      setState(() {
        _grayImage = grayscale;
        _pixilatedResult = pixelated;
        _loading = false;
      });
    }
  }

  PixelateResult _pixelate(img.Image src, int pixelSize) {
    int height = (src.height/(src.width / pixelSize)).toInt();
    setState(() {
      _pixelImageHeight = height;
    });
    print('_pixilate ${src.width} x ${src.height} to $pixelSize * $height');
    img.Image result = img.Image(width: pixelSize, height: height);
    int rangeX = (src.width / pixelSize).round();
    int rangeY = (src.height / height).round();

    print('any pixel will be $rangeX x $rangeY');

    List<List<List<double>>> debugMatrix = List.generate(
      height,
          (_) => List.filled(pixelSize, [0, 0]),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < pixelSize; x++) {
        // In a pixel for the new image

        double pixelColorCombined = 0;
        for (int origY = y*rangeY; origY < math.min((y+1)*rangeY, src.height); origY++) {
          for (int origX = x*rangeX; origX < math.min((x+1)*rangeX, src.width); origX++) {
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
          _progress += 1 / (pixelSize * height);
        });
      }
    }

    return PixelateResult(result, debugMatrix);
  }

  List<List<int>> computeRowHints(img.Image image) {
    final hints = <List<int>>[];
    for (int y = 0; y < image.height; y++) {
      final rowHints = <int>[];
      int count = 0;
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final isFilled = pixel.r == 0; // black
        if (isFilled) {
          count++;
        } else if (count > 0) {
          rowHints.add(count);
          count = 0;
        }
      }
      if (count > 0) rowHints.add(count);
      hints.add(rowHints.isEmpty ? [0] : rowHints);
    }
    return hints;
  }

  List<List<int>> computeColHints(img.Image image) {
    final hints = <List<int>>[];
    for (int x = 0; x < image.width; x++) {
      final colHints = <int>[];
      int count = 0;
      for (int y = 0; y < image.height; y++) {
        final pixel = image.getPixel(x, y);
        final isFilled = pixel.r == 0; // black
        if (isFilled) {
          count++;
        } else if (count > 0) {
          colHints.add(count);
          count = 0;
        }
      }
      if (count > 0) colHints.add(count);
      hints.add(colHints.isEmpty ? [0] : colHints);
    }
    return hints;
  }

  Future<Uint8List> capturePuzzle(GlobalKey key) async {
    RenderRepaintBoundary boundary =
    key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _savePuzzleImage() async {
    if (_puzzleKey.currentContext == null) return;

    Uint8List pngBytes = await capturePuzzle(_puzzleKey);

    final directory = await getDownloadsDirectory();
    final filePath = '${directory?.path}/griddler_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved puzzle to $filePath')),
    );
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
                      return Image.memory(img.encodePng(img.copyResize(_grayImage!, width: (_pixelSize*_resize), height: (_pixelImageHeight*_resize))));
                    } else {
                      return Container();
                    }
                  }
                ),
                // RepaintBoundary(
                //   child: LayoutBuilder(
                //       builder: (context, constraints) {
                //         if (_pixilatedResult != null) {
                //           final PixelateResult pixelated = _pixilatedResult!;
                //           print('width: $_pixelSize => ${_pixelSize*_resize} height: $_pixelImageHeight => ${_pixelImageHeight*_resize}');
                //           final widgetImage =
                //           Image.memory(img.encodePng(img.copyResize(pixelated.image, width: (_pixelSize*_resize), height: (_pixelImageHeight*_resize))));
                //
                //           return Stack(
                //             alignment: Alignment.center,
                //             children: [
                //               widgetImage, // the pixelated image
                //               Positioned.fill(
                //                 child: CustomPaint(
                //                   painter: GridPainter(
                //                     image: pixelated.image,
                //                     rowHints: computeRowHints(pixelated.image),
                //                     colHints: computeColHints(pixelated.image),
                //                     rows: _pixelImageHeight,
                //                     cols: _pixelSize,
                //                     lineColor: Colors.black,
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           );
                //         } else {
                //           return Container();
                //         }
                //       }
                //   )
                // ),
                RepaintBoundary(
                    key: _puzzleKey,
                    child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (_pixilatedResult != null) {
                            final PixelateResult pixelated = _pixilatedResult!;
                            // print('width: $_pixelSize => ${_pixelSize *
                            //     _resize} height: $_pixelImageHeight => ${_pixelImageHeight *
                            //     _resize}');
                            // final widgetImage =
                            // Image.memory(img.encodePng(img.copyResize(
                            //     pixelated.image, width: (_pixelSize * _resize),
                            //     height: (_pixelImageHeight * _resize))));

                            final rowHints = computeRowHints(pixelated.image);
                            final colHints = computeColHints(pixelated.image);
                            try {
                              final num shit = GridPainter.getHintsPadding(rowHints, _resize);
                              print('base size: ${_pixelSize * _resize}, additional size: $shit');
                            } catch (e) {
                              print('got help me $e');
                            }

                            return Positioned.fill(
                                child: CustomPaint(
                                  size: Size(
                                     ((_pixelSize * _resize) + GridPainter.getHintsPadding(rowHints, _resize)).toDouble(),
                                     ((_pixelImageHeight * _resize) + GridPainter.getHintsPadding(colHints, _resize)).toDouble(),
                                  ),
                                  painter: GridPainter(
                                    image: pixelated.image,
                                    rowHints: rowHints,
                                    colHints: colHints,
                                    cellSize: _resize.toDouble(),
                                    rows: _pixelImageHeight,
                                    cols: _pixelSize,
                                    lineColor: Colors.black,
                                  ),
                                ),
                              );
                          } else {
                            return Container();
                          }
                        }
                    )
                ),
                Expanded(
                    child: (_pixilatedResult != null) ? buildDebugTable(_pixilatedResult!.debugMatrix, _grayscaleLimit) : Container()
                ),
              ]
            ),
            SizedBox(height: 20),
            // Slider for pixel size
            PixelSlider(
              value: _pixelSize.toDouble(),
              onChanged: (val) {
                setState(() {
                  _pixelSize = val.toInt();
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
                ElevatedButton(
                  onPressed: _savePuzzleImage,
                  child: Text("Save Puzzle"),
                ),
              ],
            ),
          ],
        ),
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