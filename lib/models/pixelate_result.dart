import 'package:image/image.dart';

import 'hints.dart';

class PixelateResult {
  final Image image;
  final List<List<List<double>>> debugMatrix;
  final Hints hints;

  PixelateResult(this.image, this.debugMatrix) : hints = computeHints(image);

  static Hints computeHints(Image img) {
    return Hints(
      _computeHints(img, img.height, img.width, false),
      _computeHints(img, img.width, img.height, true),
    );
  }

  static List<List<int>> _computeHints(Image img, int mainAxis, int crossAxis, bool mainAxisForVerticalAxis) {
    final hints = <List<int>>[];
    for (int y = 0; y < mainAxis; y++) {
      final mainAxisHints = <int>[];
      int count = 0;
      for (int x = 0; x < crossAxis; x++) {
        // swapPositions is only an indication for the y and x are
        final pixel = mainAxisForVerticalAxis ? img.getPixel(y, x) : img.getPixel(x, y);
        final isFilled = pixel.r == 0; // black
        if (isFilled) {
          count++;
        } else if (count > 0) {
          mainAxisHints.add(count);
          count = 0;
        }
      }
      if (count > 0) mainAxisHints.add(count);
      hints.add(mainAxisHints.isEmpty ? [0] : mainAxisHints);
    }
    return hints;
  }
}