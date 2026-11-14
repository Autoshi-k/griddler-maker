import CoreGraphics
import Foundation
import GriddlerCore
import Observation

/// App state + the processing pipeline:
/// original → color adjustments → grayscale → block averages → threshold (+ manual edits) → clues.
/// Each stage only reruns when one of its inputs changes, and heavy stages run off the main actor.
@MainActor
@Observable
final class GriddlerModel {
    enum Stage: String, CaseIterable, Identifiable {
        case source = "Source"
        case grid = "Grid"
        case puzzle = "Puzzle"
        var id: Self { self }
    }

    enum GridOverlay: String, CaseIterable, Identifiable {
        case cells = "Cells"
        case values = "Brightness"
        var id: Self { self }
    }

    /// Images are downscaled to this before processing; plenty for up to 80 columns.
    static let workingMaxDimension = 1200
    static let columnRange = 5...80

    // MARK: UI state

    var stage: Stage = .source
    var isImporterPresented = false
    var errorMessage: String?
    var cellSize: Double = 22
    var showSolution = false
    var highlightUnresolved = true
    var gridOverlay: GridOverlay = .cells

    // MARK: User-controlled processing parameters

    var adjustments = ColorAdjustments() {
        didSet { if adjustments != oldValue { processColor() } }
    }
    /// Puzzle width in cells ("pixel size" in the original app). Rows follow the aspect ratio.
    var columns = 20 {
        didSet { if columns != oldValue { overrides = [:]; processSampling() } }
    }
    /// Blocks with average brightness at or below this become filled.
    var threshold = 0.3 {
        didSet { if threshold != oldValue { rebuildGrid() } }
    }

    // MARK: Pipeline outputs

    private(set) var imageName: String?
    private(set) var original: RGBAImage?
    private(set) var originalPreview: CGImage?
    private(set) var adjustedPreview: CGImage?
    private(set) var grayscalePreview: CGImage?
    private(set) var gridPreview: CGImage?
    private(set) var gray: GrayImage?
    private(set) var samples: BlockSamples?
    private(set) var grid: PixelGrid?
    private(set) var clues: Clues?
    private(set) var solveReport: SolveReport?
    /// Cells the user painted by hand, keyed by cell index. They win over the threshold.
    private(set) var overrides: [Int: Bool] = [:]
    private(set) var isProcessing = false

    private var colorTask: Task<Void, Never>?
    private var samplingTask: Task<Void, Never>?

    var hasImage: Bool { original != nil }

    var rows: Int {
        if let samples { return samples.rows }
        guard let original else { return 0 }
        return Pixelator.rowCount(columns: columns, imageWidth: original.width, imageHeight: original.height)
    }

    // MARK: Intents

    func load(url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let image = RGBAImage.load(contentsOf: url, maxDimension: Self.workingMaxDimension) else {
            errorMessage = "“\(url.lastPathComponent)” couldn’t be read as an image."
            return
        }
        clear()
        imageName = url.deletingPathExtension().lastPathComponent
        original = image
        originalPreview = image.makeCGImage()
        processColor()
    }

    func clear() {
        colorTask?.cancel()
        samplingTask?.cancel()
        imageName = nil
        original = nil
        originalPreview = nil
        adjustedPreview = nil
        grayscalePreview = nil
        gray = nil
        samples = nil
        overrides = [:]
        isProcessing = false
        stage = .source
        rebuildGrid()
    }

    func setCell(_ index: Int, filled: Bool) {
        guard let grid, grid.filled.indices.contains(index) else { return }
        overrides[index] = filled
        rebuildGrid()
    }

    func discardEdits() {
        overrides = [:]
        rebuildGrid()
    }

    // MARK: Pipeline

    private func processColor() {
        guard let original else { return }
        colorTask?.cancel()
        let adjustments = self.adjustments
        isProcessing = true
        colorTask = Task {
            // Coalesce rapid slider ticks.
            try? await Task.sleep(for: .milliseconds(25))
            guard !Task.isCancelled else { return }
            let (adjusted, gray) = await Task.detached(priority: .userInitiated) {
                let adjusted = original.adjusted(adjustments)
                return (adjusted, adjusted.grayscale())
            }.value
            guard !Task.isCancelled else { return }
            self.adjustedPreview = adjusted.makeCGImage()
            self.grayscalePreview = gray.makeCGImage()
            self.gray = gray
            self.processSampling()
        }
    }

    private func processSampling() {
        guard let gray else { return }
        samplingTask?.cancel()
        let columns = self.columns
        isProcessing = true
        samplingTask = Task {
            try? await Task.sleep(for: .milliseconds(15))
            guard !Task.isCancelled else { return }
            let samples = await Task.detached(priority: .userInitiated) {
                Pixelator.sample(gray, columns: columns)
            }.value
            guard !Task.isCancelled else { return }
            self.samples = samples
            self.isProcessing = false
            self.rebuildGrid()
        }
    }

    /// Cheap: thresholding, edits, clues and the solvability check.
    private func rebuildGrid() {
        guard let samples else {
            grid = nil
            clues = nil
            solveReport = nil
            gridPreview = nil
            return
        }
        var grid = samples.grid(threshold: threshold)
        for (index, value) in overrides where grid.filled.indices.contains(index) {
            grid.filled[index] = value
        }
        let clues = Clues(grid: grid)
        self.grid = grid
        self.clues = clues
        self.solveReport = NonogramSolver.solve(clues: clues)
        self.gridPreview = grid.grayImage().makeCGImage()
    }
}
