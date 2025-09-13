import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final double width;
  final img.Image? image;
  final String placeholder;

  const ImagePreview({
    super.key,
    required this.image,
    required this.width,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (image != null) {
            return Image.memory(img.encodePng(img.copyResize(image!, width: (width/2).toInt() , height: (width/2).toInt())));
          } else {
            return Container(
              width: width/2,
              height: width/2,
              color: Colors.grey,
              child: Text(placeholder),
            );
          }
        }
    );
  }
}