import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
enum Exporter {
    /// Cell size (points) used for exported images, independent of the on-screen zoom.
    static let exportCellSize: CGFloat = 24
    static let exportScale: CGFloat = 3

    static func export(_ model: GriddlerModel, solution: Bool) {
        guard let grid = model.grid, let clues = model.clues else { return }
        let canvas = PuzzleCanvas(grid: grid, clues: clues, cellSize: exportCellSize, showSolution: solution)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = exportScale
        guard let cgImage = renderer.cgImage,
              let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
            model.errorMessage = "Couldn’t render the puzzle image."
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        let base = model.imageName ?? "griddler"
        panel.nameFieldStringValue = "\(base)-\(grid.columns)x\(grid.rows)-\(solution ? "solution" : "puzzle").png"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try png.write(to: url)
        } catch {
            model.errorMessage = "Couldn’t save the image: \(error.localizedDescription)"
        }
    }
}
