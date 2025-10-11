import 'package:flutter/material.dart';
import 'package:griddler_maker/services/image_processing_service.dart';
import 'package:image/image.dart' as img;

class FilterSliders extends StatefulWidget {
  final img.Image image;
  final void Function(img.Image) onFilterChange;
  
  const FilterSliders ({ super.key, required this.image, required this.onFilterChange });

  @override
  FilterSlidersState createState() => FilterSlidersState();
}

class FilterSlidersState extends State<FilterSliders> {
  num hue = 0;
  num saturation = 1;
  double gamma = 1;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          label: "Hue",
          value: hue.toDouble(),
          max: 45,
          onChanged: (v) {
            widget.onFilterChange(ImageProcessingService.filter(widget.image, v, saturation, gamma));
            setState(() {
              hue = v;
            });
          },
        ),
        Slider(
          label: "Saturation",
          value: saturation.toDouble(),
          max: 5,
          onChanged: (v) {
            widget.onFilterChange(ImageProcessingService.filter(widget.image, hue, v, gamma));
            setState(() {
              saturation = v;
            });
          },
        ),
        Slider(
          label: "Gamma",
          value: gamma,
          max: 2,
          onChanged: (v) {
            widget.onFilterChange(ImageProcessingService.filter(widget.image, hue, saturation, v));
            setState(() {
              gamma = v;
            });
          },
        ),
      ]
    );
  }
}