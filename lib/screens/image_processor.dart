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

import '../models/pixelate_result.dart';
import '../services/image_processing_service.dart';
import '../services/image_reader.dart';
import '../widgets/grid_painter.dart';
import '../widgets/pixel_slider.dart';
import './components/image_preview.dart';

class ImageProcessor extends StatefulWidget {
  @override
  _ImageProcessorState createState() => _ImageProcessorState();
}

class _ImageProcessorState extends State<ImageProcessor> {
  img.Image? _originalImage;
  late String _errorMessage;
  PixelateResult? _pixilatedResult;
  img.Image? _grayImage;
  int _pixelSize = 20; // default pixel size
  int _pixelImageHeight = 20;
  final int _resize = 20;
  final GlobalKey _puzzleKey = GlobalKey();


  double _grayscaleLimit = 0.3; // default pixel size
  double _progress = 0.0;
  bool _loading = false;

  Future<void> _pickImage() async {
    try {
      final original = await ImageReader.pickImage();
      setState(() {
        _originalImage = original;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString();
      });
    }
  }

  Future<void> _startProcessingImage() async {
    setState(() {
      _loading = true;
    });

    // final filteredImage = ImageProcessingService.filterImage(_originalImage);
    final grayImage = ImageProcessingService.toGrayScale(_originalImage!);
    final pixelatedResult = ImageProcessingService.pixelate(grayImage, _pixelSize, _grayscaleLimit);

    setState(() {
      _grayImage = grayImage;
      _pixilatedResult = pixelatedResult;
      _pixelImageHeight = pixelatedResult.image.height;
      _loading = false;
    });
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
    List<Widget> imagesBeforePixelating = [];
    if (_originalImage != null) {
      imagesBeforePixelating.add(ImagePreview(
        image: _originalImage,
        width: (_pixelSize*_resize).toDouble(),
        placeholder: "original")
      );
    }

    if (_grayImage != null) {
      imagesBeforePixelating.add(ImagePreview(
          image: _grayImage,
          width: (_pixelSize*_resize).toDouble(),
          placeholder: "black & white")
      );
    }

    return Scaffold(
        appBar: AppBar(title: Text("Image Pixelator")),
        body: Center(
          child: Row(
          children: [
            Column(children: imagesBeforePixelating),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 10,
              children: [
                _originalImage == null
                    ? Text("Pick an image")
                    : _loading
                    ? LinearProgressIndicator(
                  semanticsLabel: 'Processing Image...',
                )
                    : RepaintBoundary(
                    key: _puzzleKey,
                    child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (_pixilatedResult != null) {
                            final PixelateResult pixelated = _pixilatedResult!;
                            return
                              Positioned.fill(
                                child: CustomPaint(
                                  size: Size(
                                    ((_pixelSize * _resize) + GridPainter.getHintsPadding(pixelated.hints.row, _resize)).toDouble(),
                                    ((_pixelImageHeight * _resize) + GridPainter.getHintsPadding(pixelated.hints.column, _resize)).toDouble(),
                                  ),
                                  painter: GridPainter(
                                    image: pixelated.image,
                                    rowHints: pixelated.hints.row,
                                    colHints: pixelated.hints.column,
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
                RepaintBoundary(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (_pixilatedResult != null) {
                        final PixelateResult pixelated = _pixilatedResult!;
                        print('width: $_pixelSize => ${_pixelSize*_resize} height: $_pixelImageHeight => ${_pixelImageHeight*_resize}');
                        final widgetImage =
                        Image.memory(img.encodePng(img.copyResize(pixelated.image, width: (_pixelSize*_resize), height: (_pixelImageHeight*_resize))));

                        return Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            widgetImage, // the pixelated image
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GridPainter(
                                  image: pixelated.image,
                                  cellSize: _resize.toDouble(),
                                  rowHints: [],
                                  colHints: [],
                                  rows: _pixelImageHeight,
                                  cols: _pixelSize,
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: (_pixilatedResult != null) ? buildDebugTable(_pixilatedResult!.debugMatrix, _grayscaleLimit) : Container()
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
                      _originalImage = null;
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