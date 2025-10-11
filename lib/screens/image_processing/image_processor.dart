import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:griddler_maker/screens/image_processing/sub_views/Image_Filtering.dart';
import 'package:griddler_maker/screens/image_processing/sub_views/image_finalizing.dart';
import 'package:griddler_maker/screens/image_processing/sub_views/image_pixelating.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/pixelate_result.dart';
import '../../services/image_processing_service.dart';
import '../../services/image_reader.dart';
import 'components/image_preview.dart';

class ImageProcessor extends StatefulWidget {
  @override
  ImageProcessorState createState() => ImageProcessorState();
}

class ImageProcessorState extends State<ImageProcessor> {
  img.Image? _originalImage;
  late String _errorMessage;
  PixelateResult? _pixilatedResult;
  img.Image? _grayImage;
  img.Image? _filteredImage;
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
      final filteredImage = original;
      final grayImage = ImageProcessingService.toGrayScale(filteredImage);
      setState(() {
        _originalImage = original;
        _filteredImage = filteredImage;
        _grayImage = grayImage;
      });
    } catch (err) {
      setState(() {
        _errorMessage = err.toString();
      });
    }
  }

  void _onChangeImageFilters(img.Image filteredImage) {
    final grayImage = ImageProcessingService.toGrayScale(filteredImage);
    setState(() {
      _filteredImage = filteredImage;
      _grayImage = grayImage;
    });
  }

  void _nextTab(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    if (tabController != null) {
      final nextIndex = (tabController.index + 1).clamp(
        0,
        tabController.length - 1,
      );
      tabController.animateTo(nextIndex);
    }
  }

  Future<void> _startProcessingImage() async {
    setState(() {
      _loading = true;
    });

    // final filteredImage = ImageProcessingService.filterImage(_originalImage);
    // final grayImage = ImageProcessingService.toGrayScale(_originalImage!);
    print("send hekop");
    if (_grayImage != null) {
      print("not empty");
      final pixelatedResult = ImageProcessingService.pixelate(_grayImage!, _pixelSize, _grayscaleLimit);

      setState(() {
        _pixilatedResult = pixelatedResult;
        _pixelImageHeight = pixelatedResult.image.height;
        _loading = false;
      });
    }
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

    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(tabs: [
              Tab(text: "Outline"),
              Tab(text: "Color"),
              Tab(text: "Effects"),
            ]),
          ),
          body: TabBarView(
            children: [
              Center(child: ImageFiltering(
                originalImage: _originalImage,
                filteredImage: _filteredImage,
                grayScaleImage: _grayImage,
                onImageSelection: _pickImage,
                onReset: () {
                  setState(() {
                    _originalImage = null;
                    _grayImage = null;
                    _pixilatedResult = null;
                  });
                },
                onChangeFilters: _onChangeImageFilters,
                onNextPressed: () {
                  _startProcessingImage().then((v) {
                    _nextTab(context);
                  });
                }
              )),
              Center(child: ImagePixelating(
                baseImage: _grayImage,
                pixelatedResult: _pixilatedResult,
                width: _pixelSize,
                height: _pixelImageHeight,
                resize: _resize,
                crossover: _grayscaleLimit,
                pixelateFunction: (PixelateResult result, double crossover) {
                  setState(() {
                    _pixilatedResult = result;
                    _pixelImageHeight = result.image.height;
                    _grayscaleLimit = crossover;
                  });
                }
              )),
              const Center(child: ImageFinalizing()),
            ],
          ),
        )
    );
    // return Scaffold(
    //     appBar: AppBar(title: Text("Image Pixelator")),
    //     body: Center(
    //       child: Row(
    //       children: [
    //         Column(children: imagesBeforePixelating),
    //         Column(
    //           crossAxisAlignment: CrossAxisAlignment.end,
    //           spacing: 10,
    //           children: [
    //             _originalImage == null
    //                 ? Text("Pick an image")
    //                 : _loading
    //                 ? LinearProgressIndicator(
    //               semanticsLabel: 'Processing Image...',
    //             )
    //                 : RepaintBoundary(
    //                 key: _puzzleKey,
    //                 child: LayoutBuilder(
    //                     builder: (context, constraints) {
    //                       if (_pixilatedResult != null) {
    //                         final PixelateResult pixelated = _pixilatedResult!;
    //                         return
    //                           Positioned.fill(
    //                             child: CustomPaint(
    //                               size: Size(
    //                                 ((_pixelSize * _resize) + GridPainter.getHintsPadding(pixelated.hints.row, _resize)).toDouble(),
    //                                 ((_pixelImageHeight * _resize) + GridPainter.getHintsPadding(pixelated.hints.column, _resize)).toDouble(),
    //                               ),
    //                               painter: GridPainter(
    //                                 image: pixelated.image,
    //                                 rowHints: pixelated.hints.row,
    //                                 colHints: pixelated.hints.column,
    //                                 cellSize: _resize.toDouble(),
    //                                 rows: _pixelImageHeight,
    //                                 cols: _pixelSize,
    //                                 lineColor: Colors.black,
    //                               ),
    //                             ),
    //                           );
    //                       } else {
    //                         return Container();
    //                       }
    //                     }
    //                 )
    //             ),
    //             RepaintBoundary(
    //               child: LayoutBuilder(
    //                 builder: (context, constraints) {
    //                   if (_pixilatedResult != null) {
    //                     final PixelateResult pixelated = _pixilatedResult!;
    //                     print('width: $_pixelSize => ${_pixelSize*_resize} height: $_pixelImageHeight => ${_pixelImageHeight*_resize}');
    //                     final widgetImage =
    //                     Image.memory(img.encodePng(img.copyResize(pixelated.image, width: (_pixelSize*_resize), height: (_pixelImageHeight*_resize))));
    //
    //                     return Stack(
    //                       alignment: Alignment.bottomLeft,
    //                       children: [
    //                         widgetImage, // the pixelated image
    //                         Positioned.fill(
    //                           child: CustomPaint(
    //                             painter: GridPainter(
    //                               image: pixelated.image,
    //                               cellSize: _resize.toDouble(),
    //                               rowHints: [],
    //                               colHints: [],
    //                               rows: _pixelImageHeight,
    //                               cols: _pixelSize,
    //                               lineColor: Colors.black,
    //                             )
    //                           ),
    //                         ),
    //                       ]
    //                     );
    //                   } else {
    //                     return Container();
    //                   }
    //                 }
    //               )
    //             ),
    //           ],
    //         ),
    //         Column(
    //           mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             Expanded(
    //                 child: (_pixilatedResult != null) ? buildDebugTable(_pixilatedResult!.debugMatrix, _grayscaleLimit) : Container()
    //             ),
    //             SizedBox(height: 20),
    //             // Slider for pixel size
    //             PixelSlider(
    //               value: _pixelSize.toDouble(),
    //               onChanged: (val) {
    //                 setState(() {
    //                   _pixelSize = val.toInt();
    //                 });
    //               },
    //             ),
    //             RatioSlider(
    //               value: _grayscaleLimit,
    //               onChanged: (val) {
    //                 setState(() {
    //                   _grayscaleLimit = val;
    //                 });
    //               },
    //             ),
    //             ElevatedButton(
    //               onPressed: _pickImage,
    //               child: Text("Choose Image"),
    //             ),
    //             ElevatedButton(
    //               onPressed: _startProcessingImage,
    //               child: Text("Generate"),
    //             ),
    //             ElevatedButton(
    //               onPressed: () {
    //                 setState(() {
    //                   _originalImage = null;
    //                   _grayImage = null;
    //                   _pixilatedResult = null;
    //                 });
    //               },
    //               child: Text("Reset"),
    //             ),
    //             ElevatedButton(
    //               onPressed: _savePuzzleImage,
    //               child: Text("Save Puzzle"),
    //             ),
    //           ],
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}

