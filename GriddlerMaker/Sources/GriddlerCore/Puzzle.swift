import Foundation

/// The solution picture: `true` = filled (black) cell. Row-major.
public struct PixelGrid: Sendable, Equatable {
    public let columns: Int
    public let rows: Int
    public var filled: [Bool]

    public init(columns: Int, rows: Int, filled: [Bool]) {
        precondition(filled.count == columns * rows)
        self.columns = columns
        self.rows = rows
        self.filled = filled
    }

    public func index(row: Int, column: Int) -> Int { row * columns + column }

    public subscript(row: Int, column: Int) -> Bool {
        get { filled[index(row: row, column: column)] }
        set { filled[index(row: row, column: column)] = newValue }
    }

    public func row(_ r: Int) -> [Bool] { Array(filled[(r * columns)..<((r + 1) * columns)]) }
    public func column(_ c: Int) -> [Bool] { (0..<rows).map { filled[$0 * columns + c] } }

    public var filledCount: Int { filled.lazy.filter { $0 }.count }

    /// 1 pixel per cell, for previews.
    public func grayImage() -> GrayImage {
        GrayImage(width: columns, height: rows, pixels: filled.map { $0 ? 0 : 255 })
    }
}

/// Run-length clues for each row (left to right) and column (top to bottom).
/// An empty line has no clues; renderers show it as "0".
public struct Clues: Sendable, Equatable {
    public let rows: [[Int]]
    public let columns: [[Int]]

    public init(rows: [[Int]], columns: [[Int]]) {
        self.rows = rows
        self.columns = columns
    }

    public init(grid: PixelGrid) {
        rows = (0..<grid.rows).map { Clues.runs(of: grid.row($0)) }
        columns = (0..<grid.columns).map { Clues.runs(of: grid.column($0)) }
    }

    public static func runs<S: Sequence>(of line: S) -> [Int] where S.Element == Bool {
        var result: [Int] = []
        var count = 0
        for filled in line {
            if filled {
                count += 1
            } else if count > 0 {
                result.append(count)
                count = 0
            }
        }
        if count > 0 { result.append(count) }
        return result
    }
}
