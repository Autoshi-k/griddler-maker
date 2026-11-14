import XCTest
@testable import GriddlerCore

final class CluesTests: XCTestCase {
    func testRuns() {
        XCTAssertEqual(Clues.runs(of: [true, true, false, true]), [2, 1])
        XCTAssertEqual(Clues.runs(of: [false, false]), [])
        XCTAssertEqual(Clues.runs(of: [true, true, true]), [3])
    }

    func testCluesFromGrid() {
        // ##.
        // .#.
        let grid = PixelGrid(columns: 3, rows: 2, filled: [true, true, false, false, true, false])
        let clues = Clues(grid: grid)
        XCTAssertEqual(clues.rows, [[2], [1]])
        XCTAssertEqual(clues.columns, [[1], [2], []])
    }
}

final class PixelatorTests: XCTestCase {
    func testAspectRatioRows() {
        XCTAssertEqual(Pixelator.rowCount(columns: 20, imageWidth: 400, imageHeight: 200), 10)
        XCTAssertEqual(Pixelator.rowCount(columns: 20, imageWidth: 200, imageHeight: 400), 40)
    }

    func testThresholdingAveragesBlocks() {
        // 4x2 image: left half black, right half white -> 2x1 grid.
        let img = GrayImage(width: 4, height: 2, pixels: [0, 0, 255, 255, 0, 0, 255, 255])
        let samples = Pixelator.sample(img, columns: 2)
        XCTAssertEqual(samples.columns, 2)
        XCTAssertEqual(samples.rows, 1)
        XCTAssertEqual(samples.averages, [0, 1])
        XCTAssertEqual(samples.sums, [0, 4])
        XCTAssertEqual(samples.grid(threshold: 0.3).filled, [true, false])
    }

    func testUnevenBlocksCoverWholeImage() {
        // 5 px wide into 2 columns: every pixel must be counted exactly once.
        let img = GrayImage(width: 5, height: 1, pixels: [255, 255, 255, 255, 255])
        let samples = Pixelator.sample(img, columns: 2)
        XCTAssertEqual(samples.sums.reduce(0, +), 5, accuracy: 1e-9)
        XCTAssertEqual(samples.averages, [1, 1])
    }
}

final class ColorTests: XCTestCase {
    func testGrayscaleWeights() {
        let img = RGBAImage(width: 1, height: 1, pixels: [255, 0, 0, 255])
        XCTAssertEqual(img.grayscale().pixels, [76]) // 0.299 * 255
    }

    func testIdentityAdjustmentIsNoOp() {
        let img = RGBAImage(width: 2, height: 1, pixels: [10, 20, 30, 255, 200, 100, 50, 255])
        XCTAssertEqual(img.adjusted(.identity), img)
    }

    func testInvertAndZeroSaturation() {
        let img = RGBAImage(width: 1, height: 1, pixels: [0, 0, 0, 255])
        XCTAssertEqual(img.adjusted(ColorAdjustments(invert: true)).pixels, [255, 255, 255, 255])
        let red = RGBAImage(width: 1, height: 1, pixels: [255, 0, 0, 255])
        let desat = red.adjusted(ColorAdjustments(saturation: 0)).pixels
        XCTAssertEqual(desat[0], desat[1])
        XCTAssertEqual(desat[1], desat[2])
    }
}

final class SolverTests: XCTestCase {
    func testLineFullyDetermined() {
        let line = [CellState](repeating: .unknown, count: 5)
        XCTAssertEqual(NonogramSolver.solveLine(clues: [2, 2], line: line), [.filled, .filled, .empty, .filled, .filled])
        XCTAssertEqual(NonogramSolver.solveLine(clues: [], line: line), [CellState](repeating: .empty, count: 5))
    }

    func testLineOverlap() {
        // A 4-block in 6 cells always covers the middle two.
        let solved = NonogramSolver.solveLine(clues: [4], line: [CellState](repeating: .unknown, count: 6))
        XCTAssertEqual(solved, [.unknown, .unknown, .filled, .filled, .unknown, .unknown])
    }

    func testLineUsesKnownCells() {
        var line = [CellState](repeating: .unknown, count: 5)
        line[0] = .filled
        XCTAssertEqual(NonogramSolver.solveLine(clues: [2], line: line), [.filled, .filled, .empty, .empty, .empty])
    }

    func testLineContradiction() {
        let line: [CellState] = [.filled, .empty, .filled]
        XCTAssertNil(NonogramSolver.solveLine(clues: [3], line: line))
    }

    func testSolvablePuzzle() {
        // A plus sign is uniquely solvable by line logic.
        let grid = PixelGrid(columns: 3, rows: 3, filled: [
            false, true, false,
            true, true, true,
            false, true, false,
        ])
        let report = NonogramSolver.solve(clues: Clues(grid: grid))
        XCTAssertTrue(report.isSolved)
        XCTAssertEqual(report.cells.map { $0 == .filled }, grid.filled)
    }

    func testAmbiguousPuzzle() {
        // A diagonal pair has two solutions (either diagonal).
        let grid = PixelGrid(columns: 2, rows: 2, filled: [true, false, false, true])
        let report = NonogramSolver.solve(clues: Clues(grid: grid))
        XCTAssertFalse(report.isSolved)
        XCTAssertFalse(report.contradiction)
        XCTAssertEqual(report.unresolvedCount, 4)
    }
}
