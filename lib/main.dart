import 'package:flutter/material.dart';
import 'screens/image_processor.dart';

void main() {
  runApp(const PixelatorApp());
}

class PixelatorApp extends StatelessWidget {
  const PixelatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Pixelator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageProcessor(),
    );
  }
}