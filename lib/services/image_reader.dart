import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart';


class ImageReader {
  static Future<Image> pickImage() async {
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pick == null) throw Exception("No image selected");

    final bytes = File(pick.path).readAsBytesSync();
    final image = decodeImage(bytes);
    if (image == null) throw Exception("Failed to decode image");

    return image;
  }
}