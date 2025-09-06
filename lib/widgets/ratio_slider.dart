import 'package:flutter/material.dart';

class RatioSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RatioSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Value: ${value.toStringAsFixed(2)}"),
        Slider(
          value: value,
          min: 0.0,
          max: 1.0,
          divisions: 50, // step of 0.02
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
