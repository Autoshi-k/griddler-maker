import 'package:flutter/material.dart';

class PixelSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const PixelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 5,
    this.max = 35,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Pixel Size: ${value.toInt()}"),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toInt().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}