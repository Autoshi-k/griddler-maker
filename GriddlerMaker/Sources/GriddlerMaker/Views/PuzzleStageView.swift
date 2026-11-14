import GriddlerCore
import SwiftUI

struct PuzzleStageView: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            CenteredScrollView {
                if let grid = model.grid, let clues = model.clues {
                    PuzzleCanvas(grid: grid, clues: clues, cellSize: model.cellSize, showSolution: model.showSolution)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                } else {
                    ProgressView()
                }
            }

            Divider()

            HStack {
                Toggle("Show solution", isOn: $model.showSolution)
                Spacer()
                Button("Export Puzzle…") { Exporter.export(model, solution: false) }
                Button("Export Solution…") { Exporter.export(model, solution: true) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }
}

/// The printable griddler: clue numbers on the top and left, grid on the bottom right.
/// Always drawn black on white so it looks the same on screen, in dark mode, and exported.
struct PuzzleCanvas: View {
    let grid: PixelGrid
    let clues: Clues
    let cellSize: CGFloat
    let showSolution: Bool

    private var rowClueSlots: Int { max(1, clues.rows.map(\.count).max() ?? 0) }
    private var columnClueSlots: Int { max(1, clues.columns.map(\.count).max() ?? 0) }
    private var margin: CGFloat { cellSize * 0.6 }
    private var gridOrigin: CGPoint {
        CGPoint(x: margin + CGFloat(rowClueSlots) * cellSize, y: margin + CGFloat(columnClueSlots) * cellSize)
    }
    private var totalSize: CGSize {
        CGSize(
            width: gridOrigin.x + CGFloat(grid.columns) * cellSize + margin,
            height: gridOrigin.y + CGFloat(grid.rows) * cellSize + margin
        )
    }

    var body: some View {
        Canvas { ctx, size in draw(in: &ctx, size: size) }
            .frame(width: totalSize.width, height: totalSize.height)
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let origin = gridOrigin
        let gridWidth = CGFloat(grid.columns) * cellSize
        let gridHeight = CGFloat(grid.rows) * cellSize
        let rowClueWidth = CGFloat(rowClueSlots) * cellSize
        let columnClueHeight = CGFloat(columnClueSlots) * cellSize

        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

        // Clue areas, shaded in alternating bands of 5 so long lines are easy to follow.
        for c in stride(from: 0, to: grid.columns, by: 5) {
            let band = CGRect(
                x: origin.x + CGFloat(c) * cellSize, y: margin,
                width: CGFloat(min(5, grid.columns - c)) * cellSize, height: columnClueHeight
            )
            ctx.fill(Path(band), with: .color(Color(white: (c / 5).isMultiple(of: 2) ? 0.95 : 0.89)))
        }
        for r in stride(from: 0, to: grid.rows, by: 5) {
            let band = CGRect(
                x: margin, y: origin.y + CGFloat(r) * cellSize,
                width: rowClueWidth, height: CGFloat(min(5, grid.rows - r)) * cellSize
            )
            ctx.fill(Path(band), with: .color(Color(white: (r / 5).isMultiple(of: 2) ? 0.95 : 0.89)))
        }

        if showSolution {
            for index in grid.filled.indices where grid.filled[index] {
                let cell = CGRect(
                    x: origin.x + CGFloat(index % grid.columns) * cellSize,
                    y: origin.y + CGFloat(index / grid.columns) * cellSize,
                    width: cellSize, height: cellSize
                )
                ctx.fill(Path(cell), with: .color(Color(white: 0.12)))
            }
        }

        let font = Font.system(size: cellSize * 0.55, weight: .semibold, design: .rounded).monospacedDigit()
        func drawClue(_ value: Int, at point: CGPoint) {
            ctx.draw(Text("\(value)").font(font).foregroundColor(.black), at: point, anchor: .center)
        }

        for (r, line) in clues.rows.enumerated() {
            let values = line.isEmpty ? [0] : line
            let y = origin.y + (CGFloat(r) + 0.5) * cellSize
            for (i, value) in values.enumerated() {
                drawClue(value, at: CGPoint(x: origin.x - (CGFloat(values.count - i) - 0.5) * cellSize, y: y))
            }
        }
        for (c, line) in clues.columns.enumerated() {
            let values = line.isEmpty ? [0] : line
            let x = origin.x + (CGFloat(c) + 0.5) * cellSize
            for (i, value) in values.enumerated() {
                drawClue(value, at: CGPoint(x: x, y: origin.y - (CGFloat(values.count - i) - 0.5) * cellSize))
            }
        }

        GridLines.draw(
            in: &ctx, origin: origin, columns: grid.columns, rows: grid.rows, cellSize: cellSize,
            thin: Color(white: 0.55), extendTop: columnClueHeight, extendLeft: rowClueWidth
        )
        // Outline the clue areas.
        ctx.stroke(
            Path(CGRect(x: origin.x, y: margin, width: gridWidth, height: columnClueHeight)),
            with: .color(.black), lineWidth: 1.5
        )
        ctx.stroke(
            Path(CGRect(x: margin, y: origin.y, width: rowClueWidth, height: gridHeight)),
            with: .color(.black), lineWidth: 1.5
        )
    }
}
