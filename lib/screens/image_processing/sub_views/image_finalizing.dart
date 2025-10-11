import 'package:flutter/material.dart';
import 'package:griddler_maker/screens/image_processing/layout.dart';

class ImageFinalizing extends StatelessWidget {
  const ImageFinalizing({super.key});

  @override
  Widget build(BuildContext context) {
    return Layout(
      mainArea: const Stack(
        alignment: AlignmentGeometry.bottomRight,
        children: [
          Text("final Image Here")
        ],
      ),
      secondaryArea: Column(
        children: [
          ElevatedButton(onPressed: () {}, child: const Text("Add Outline")),
          Slider(
            value: 0.5,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}