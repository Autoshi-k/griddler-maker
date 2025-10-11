import 'dart:math' as math;
import 'package:image/image.dart' as image;
import '../models/pixelate_result.dart';

class ImageProcessingService {
  static image.Image toGrayScale(image.Image img) {
    image.Image origImg = img.clone();
    return image.grayscale(origImg);
  }

  static image.Image filter(image.Image img, num hue, num saturation, num gamma) {
    image.Image origImg = img.clone();
    // Example: increase brightness + saturation
    return image.adjustColor(origImg,
      hue: hue,
      saturation: saturation,
      gamma: gamma
    );
  }

  static PixelateResult pixelate(image.Image img, int width, double turningPoint) {
    int height = (img.height/(img.width / width)).toInt();
    print('_pixilate ${img.width} x ${img.height} to $width * $height');
    image.Image result = image.Image(width: width, height: height);
    int rangeX = (img.width / width).round();
    int rangeY = (img.height / height).round();

    print('any pixel will be $rangeX x $rangeY');

    List<List<List<double>>> debugMatrix = List.generate(
      height,
          (_) => List.filled(width, [0, 0]),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // In a pixel for the new image

        double pixelColorCombined = 0;
        for (int origY = y*rangeY; origY < math.min((y+1)*rangeY, img.height); origY++) {
          for (int origX = x*rangeX; origX < math.min((x+1)*rangeX, img.width); origX++) {
            // Take the color of the top-left pixel of the block
            image.Pixel pixel = img.getPixel(origX, origY);
            image.Color color = pixel.clone();
            // since it's grayscale, r == g == b

            try {
              num value = color.r / 255.0; // normalize to [0,1]
              pixelColorCombined += value;
            } catch (err) {
              num redColor = color.r;
              print('err on pixel [$origX, $origY] color of $redColor. err: $err');
            }
          }
        }

        final double avg = pixelColorCombined / (rangeX * rangeY);
        final double pixelColor = avg > turningPoint ? 255 : 0;
        result.setPixelRgb(x, y, pixelColor, pixelColor, pixelColor);
        debugMatrix[y][x] = [avg, pixelColorCombined];
      }
    }

    return PixelateResult(result, debugMatrix);
  }
}