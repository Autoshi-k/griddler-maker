# Griddler Maker (Swift)

Native macOS (SwiftUI) rewrite of the Flutter griddler maker: turn a picture into a
nonogram puzzle.

## Run

```sh
swift run -c release GriddlerMaker            # or: open Package.swift in Xcode and Run
swift run -c release GriddlerMaker photo.jpg  # open an image right away
swift test                                    # core logic tests
```

Requires macOS 14+.

## Pipeline

Same as the original app:

1. **Color adjust**: hue, saturation, gamma (+ invert)
2. **Black & white**: luminance grayscale (0.299 R + 0.587 G + 0.114 B)
3. **Areas**: split into `columns` × rows blocks (rows follow the aspect ratio) and average each block's brightness
4. **Threshold**: blocks with average ≤ threshold become filled cells
5. **Clues**: run lengths per row and column

## Layout

- `Sources/GriddlerCore`: pure processing and puzzle logic (no UI), unit tested
  - `Bitmaps.swift`: RGBA and gray buffers, loading with EXIF orientation
  - `ColorAdjustments.swift`: hue, saturation, gamma, invert, grayscale
  - `Pixelator.swift`: block averaging and thresholding
  - `Puzzle.swift`: grid and clues
  - `Solver.swift`: line-logic solver that checks whether the puzzle can be solved without guessing
- `Sources/GriddlerMaker`: SwiftUI app (model, sidebar controls, Source/Grid/Puzzle views, PNG export)
