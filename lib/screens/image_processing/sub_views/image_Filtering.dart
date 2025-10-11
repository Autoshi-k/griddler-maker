import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:griddler_maker/screens/image_processing/layout.dart';

import '../components/filter_sliders.dart';
import '../components/image_preview.dart';

class ImageFiltering extends StatelessWidget {
  final bool _loading = false;
  final img.Image? originalImage;
  final img.Image? filteredImage;
  final img.Image? grayScaleImage;
  final VoidCallback onImageSelection;
  final void Function(img.Image) onChangeFilters;
  final VoidCallback onReset;
  final VoidCallback onNextPressed;

  const ImageFiltering({
    super.key,
    required this.originalImage,
    required this.filteredImage,
    required this.grayScaleImage,
    required this.onImageSelection,
    required this.onChangeFilters,
    required this.onReset,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Layout(
      mainArea: Stack(
        alignment: AlignmentGeometry.bottomRight,
        fit: StackFit.passthrough,
        children: [
          originalImage == null
              ? ElevatedButton(onPressed: onImageSelection, child: const Text("Pick an Image"))
              : _loading ? const LinearProgressIndicator(semanticsLabel: 'Processing Image...')
              : ImagePreview(image: originalImage, width: 600.toDouble(), placeholder: "original"),
          // Bottom right previews
          if (grayScaleImage != null && filteredImage != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filtered preview (placeholder for now)
                  ImagePreview(
                    image: filteredImage,
                    width: 300,
                    placeholder: "color filter",
                  ),
                  const SizedBox(width: 8),
                  // Black & white preview (placeholder for now)
                  ImagePreview(
                    image: grayScaleImage,
                    width: 300,
                    placeholder: "black & white",
                  ),
                ],
              ),
            ),
        ]
      ),
      secondaryArea: Column(
        children: [
          ElevatedButton(onPressed: onReset, child: const Text("Reset")),
          originalImage != null ?
            FilterSliders(
              image: originalImage!,
              onFilterChange: onChangeFilters,
            )
          : Container(),
          ElevatedButton(
            onPressed: onNextPressed,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}