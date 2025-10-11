import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../models/pixelate_result.dart';
import '../../../services/image_processing_service.dart';
import '../../../widgets/pixel_slider.dart';
import '../../../widgets/ratio_slider.dart';

class PixelSliders extends StatefulWidget {
  final img.Image image;
  final void Function(PixelateResult, double) onSettingChange;

  const PixelSliders ({ super.key, required this.image, required this.onSettingChange });

  @override
  PixelSlidersState createState() => PixelSlidersState();
}

class PixelSlidersState extends State<PixelSliders> {
  int width = 20;
  double crossover = 0.3; // todo need to get this from parent
  final int timeoutMS = 500;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PixelSlider(
          value: width.toDouble(),
          onChanged: (val) {
            setState(() {
              width = val.toInt();
            });
          },
        ),
        RatioSlider(
          value: crossover,
          onChanged: (val) {
            setState(() {
              crossover = val;
            });
          },
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSettingChange(ImageProcessingService.pixelate(widget.image, width, crossover), crossover);
          },
          child: const Text("Commit Changes")),
      ]
    );
  }
}