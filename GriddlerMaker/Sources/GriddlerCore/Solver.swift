import Foundation

public enum CellState: UInt8, Sendable {
    case unknown, filled, empty
}

public struct SolveReport: Sendable, Equatable {
    public let columns: Int
    public let rows: Int
    /// What line-by-line logic could deduce. `.unknown` cells need guessing
    /// (or the clues allow more than one picture).
    public let cells: [CellState]
    public let contradiction: Bool

    public var unresolvedCount: Int { cells.lazy.filter { $0 == .unknown }.count }
    public var isSolved: Bool { !contradiction && unresolvedCount == 0 }
}

/// Checks whether a puzzle can be solved by a human using pure line logic:
/// repeatedly take a row or column, find every cell that has the same value in
/// all arrangements consistent with its clues and the known cells, and propagate.
public enum NonogramSolver {
    public static func solve(clues: Clues) -> SolveReport {
        let rows = clues.rows.count
        let columns = clues.columns.count
        var cells = [CellState](repeating: .unknown, count: rows * columns)
        var dirtyRows = Set(0..<rows)
        var dirtyColumns = Set(0..<columns)

        func fail() -> SolveReport {
            SolveReport(columns: columns, rows: rows, cells: cells, contradiction: true)
        }

        while !dirtyRows.isEmpty || !dirtyColumns.isEmpty {
            let rowBatch = dirtyRows
            dirtyRows.removeAll()
            for r in rowBatch.sorted() {
                let line = (0..<columns).map { cells[r * columns + $0] }
                guard let solved = solveLine(clues: clues.rows[r], line: line) else { return fail() }
                for c in 0..<columns where solved[c] != line[c] {
                    cells[r * columns + c] = solved[c]
                    dirtyColumns.insert(c)
                }
            }

            let columnBatch = dirtyColumns
            dirtyColumns.removeAll()
            for c in columnBatch.sorted() {
                let line = (0..<rows).map { cells[$0 * columns + c] }
                guard let solved = solveLine(clues: clues.columns[c], line: line) else { return fail() }
                for r in 0..<rows where solved[r] != line[r] {
                    cells[r * columns + c] = solved[r]
                    dirtyRows.insert(r)
                }
            }
        }
        return SolveReport(columns: columns, rows: rows, cells: cells, contradiction: false)
    }

    /// Returns the line with every forced cell filled in, or nil if no arrangement fits.
    /// O(n·k) dynamic programming over (position, clues placed).
    public static func solveLine(clues: [Int], line: [CellState]) -> [CellState]? {
        let n = line.count
        let k = clues.count
        let stride = k + 1

        var emptyPrefix = [Int](repeating: 0, count: n + 1)
        for i in 0..<n { emptyPrefix[i + 1] = emptyPrefix[i] + (line[i] == .empty ? 1 : 0) }

        // A block of `length` can start at `start` if it stays in bounds, covers no
        // known-empty cell, and isn't immediately followed by a known-filled cell.
        func blockFits(_ start: Int, _ length: Int) -> Bool {
            let end = start + length
            guard end <= n, emptyPrefix[end] == emptyPrefix[start] else { return false }
            return end == n || line[end] != .filled
        }
        func afterBlock(_ start: Int, _ length: Int) -> Int { min(start + length + 1, n) }

        // feasible[i][j]: cells i..<n can be completed using clues j..<k.
        var feasible = [Bool](repeating: false, count: (n + 1) * stride)
        feasible[n * stride + k] = true
        if n > 0 {
            for i in Swift.stride(from: n - 1, through: 0, by: -1) {
                for j in 0...k {
                    var ok = line[i] != .filled && feasible[(i + 1) * stride + j]
                    if !ok, j < k, blockFits(i, clues[j]) {
                        ok = feasible[afterBlock(i, clues[j]) * stride + j + 1]
                    }
                    feasible[i * stride + j] = ok
                }
            }
        }
        guard feasible[0] else { return nil }

        // Walk forward through reachable states, recording which values each cell can take.
        var reachable = [Bool](repeating: false, count: (n + 1) * stride)
        reachable[0] = true
        var canEmpty = [Bool](repeating: false, count: n)
        var fillDelta = [Int](repeating: 0, count: n + 1)
        for i in 0..<n {
            for j in 0...k where reachable[i * stride + j] && feasible[i * stride + j] {
                if line[i] != .filled && feasible[(i + 1) * stride + j] {
                    canEmpty[i] = true
                    reachable[(i + 1) * stride + j] = true
                }
                if j < k, blockFits(i, clues[j]) {
                    let next = afterBlock(i, clues[j])
                    if feasible[next * stride + j + 1] {
                        let end = i + clues[j]
                        fillDelta[i] += 1
                        fillDelta[end] -= 1
                        if end < n { canEmpty[end] = true }
                        reachable[next * stride + j + 1] = true
                    }
                }
            }
        }

        var result = line
        var running = 0
        for i in 0..<n {
            running += fillDelta[i]
            switch (running > 0, canEmpty[i]) {
            case (true, false): result[i] = .filled
            case (false, true): result[i] = .empty
            case (false, false): return nil
            case (true, true): break
            }
        }
        return result
    }
}
