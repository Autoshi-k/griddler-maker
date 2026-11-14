import Foundation

/// Average brightness of every block of the source image.
/// Kept separate from thresholding so moving the threshold slider doesn't
/// rescan the image.
public struct BlockSamples: Sendable, Equatable {
    public let columns: Int
    public let rows: Int
    /// Mean brightness per block, 0 = black ... 1 = white. Row-major.
    public let averages: [Double]
    /// Sum of normalized brightness per block (the second value of the old debug matrix).
    public let sums: [Double]

    public init(columns: Int, rows: Int, averages: [Double], sums: [Double]) {
        precondition(averages.count == columns * rows && sums.count == averages.count)
        self.columns = columns
        self.rows = rows
        self.averages = averages
        self.sums = sums
    }

    /// Blocks at or below `threshold` become filled (black) cells.
    public func grid(threshold: Double) -> PixelGrid {
        PixelGrid(columns: columns, rows: rows, filled: averages.map { $0 <= threshold })
    }
}

public enum Pixelator {
    /// Rows follow the image's aspect ratio for a given column count.
    public static func rowCount(columns: Int, imageWidth: Int, imageHeight: Int) -> Int {
        guard imageWidth > 0 else { return 0 }
        return max(1, min(imageHeight, Int(Double(imageHeight) * Double(columns) / Double(imageWidth))))
    }

    /// Splits the image into `columns` x (aspect-derived) rows blocks and averages each one.
    ///
    /// Same idea as the original Dart `pixelate`, with two fixes: block edges are
    /// distributed proportionally so no source pixels are dropped or double-counted,
    /// and each block is divided by the pixels it actually contains.
    public static func sample(_ image: GrayImage, columns requested: Int) -> BlockSamples {
        let columns = min(max(1, requested), image.width)
        let rows = rowCount(columns: columns, imageWidth: image.width, imageHeight: image.height)
        let xBounds = (0...columns).map { $0 * image.width / columns }
        let yBounds = (0...rows).map { $0 * image.height / rows }

        var sums = [Double](repeating: 0, count: columns * rows)
        image.pixels.withUnsafeBufferPointer { px in
            for r in 0..<rows {
                for y in yBounds[r]..<yBounds[r + 1] {
                    let rowStart = y * image.width
                    for c in 0..<columns {
                        var s = 0
                        for x in xBounds[c]..<xBounds[c + 1] { s += Int(px[rowStart + x]) }
                        sums[r * columns + c] += Double(s) / 255
                    }
                }
            }
        }

        var averages = [Double](repeating: 0, count: sums.count)
        for r in 0..<rows {
            let h = yBounds[r + 1] - yBounds[r]
            for c in 0..<columns {
                let count = h * (xBounds[c + 1] - xBounds[c])
                let i = r * columns + c
                averages[i] = count > 0 ? sums[i] / Double(count) : 1
            }
        }
        return BlockSamples(columns: columns, rows: rows, averages: averages, sums: sums)
    }
}
