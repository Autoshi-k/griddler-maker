import GriddlerCore
import SwiftUI

/// The pixelated picture as an editable grid, plus the per-block brightness
/// values (the old debug table) and the solver's unresolved cells.
struct GridStageView: View {
    @Environment(GriddlerModel.self) private var model
    @State private var hovered: Int?

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            CenteredScrollView {
                if let grid = model.grid, let samples = model.samples {
                    GridEditorCanvas(
                        grid: grid,
                        samples: samples,
                        report: model.highlightUnresolved ? model.solveReport : nil,
                        edited: Set(model.overrides.keys),
                        overlay: model.gridOverlay,
                        cellSize: model.cellSize,
                        hovered: $hovered,
                        onPaint: { model.setCell($0, filled: $1) }
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                } else {
                    ProgressView()
                }
            }

            Divider()

            HStack(spacing: 16) {
                Picker("Show", selection: $model.gridOverlay) {
                    ForEach(GriddlerModel.GridOverlay.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()

                Toggle("Highlight unresolved", isOn: $model.highlightUnresolved)

                Spacer()

                Text(hoverDescription)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private var hoverDescription: String {
        guard let hovered, let grid = model.grid, let samples = model.samples,
              grid.filled.indices.contains(hovered) else {
            return "Click or drag to paint cells"
        }
        let row = hovered / grid.columns + 1
        let col = hovered % grid.columns + 1
        let avg = samples.averages[hovered].formatted(.number.precision(.fractionLength(2)))
        let sum = samples.sums[hovered].formatted(.number.precision(.fractionLength(1)))
        var state = grid.filled[hovered] ? "filled" : "empty"
        if model.overrides[hovered] != nil { state += " (painted)" }
        return "Row \(row), Col \(col) · brightness \(avg) · sum \(sum) · \(state)"
    }
}

private struct GridEditorCanvas: View {
    let grid: PixelGrid
    let samples: BlockSamples
    let report: SolveReport?
    let edited: Set<Int>
    let overlay: GriddlerModel.GridOverlay
    let cellSize: CGFloat
    @Binding var hovered: Int?
    let onPaint: (Int, Bool) -> Void

    /// While dragging, every touched cell is set to the value the first cell was toggled to.
    @State private var paintValue: Bool?

    var body: some View {
        Canvas { ctx, size in draw(in: &ctx, size: size) }
            .frame(width: CGFloat(grid.columns) * cellSize, height: CGFloat(grid.rows) * cellSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let index = cellIndex(at: value.location) else { return }
                        let target = paintValue ?? !grid.filled[index]
                        paintValue = target
                        if grid.filled[index] != target { onPaint(index, target) }
                    }
                    .onEnded { _ in paintValue = nil }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let point): hovered = cellIndex(at: point)
                case .ended: hovered = nil
                }
            }
    }

    private func cellIndex(at point: CGPoint) -> Int? {
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        guard point.x >= 0, point.y >= 0, col < grid.columns, row < grid.rows else { return nil }
        return grid.index(row: row, column: col)
    }

    private func rect(_ index: Int) -> CGRect {
        CGRect(
            x: CGFloat(index % grid.columns) * cellSize,
            y: CGFloat(index / grid.columns) * cellSize,
            width: cellSize, height: cellSize
        )
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

        for index in grid.filled.indices {
            let r = rect(index)
            switch overlay {
            case .cells:
                if grid.filled[index] { ctx.fill(Path(r), with: .color(.black)) }
            case .values:
                ctx.fill(Path(r), with: .color(Color(white: samples.averages[index])))
                if grid.filled[index] {
                    let d = cellSize * 0.34
                    let dot = CGRect(x: r.midX - d / 2, y: r.midY - d / 2, width: d, height: d)
                    ctx.fill(Path(ellipseIn: dot), with: .color(.accentColor))
                }
            }

            if let report, report.cells[index] == .unknown {
                ctx.fill(Path(r), with: .color(.orange.opacity(0.45)))
            }

            if edited.contains(index) {
                var corner = Path()
                corner.move(to: CGPoint(x: r.maxX - cellSize * 0.35, y: r.minY))
                corner.addLine(to: CGPoint(x: r.maxX, y: r.minY))
                corner.addLine(to: CGPoint(x: r.maxX, y: r.minY + cellSize * 0.35))
                corner.closeSubpath()
                ctx.fill(corner, with: .color(.blue))
            }
        }

        GridLines.draw(
            in: &ctx, origin: .zero, columns: grid.columns, rows: grid.rows, cellSize: cellSize,
            thin: Color.gray.opacity(0.5)
        )

        if let hovered, grid.filled.indices.contains(hovered) {
            ctx.stroke(Path(rect(hovered).insetBy(dx: 1, dy: 1)), with: .color(.accentColor), lineWidth: 2)
        }
    }
}

/// Grid lines with a heavy line every 5 cells and a heavy border, as on printed griddlers.
enum GridLines {
    static func draw(
        in ctx: inout GraphicsContext, origin: CGPoint, columns: Int, rows: Int, cellSize: CGFloat,
        thin: Color = .gray, thick: Color = .black,
        extendTop: CGFloat = 0, extendLeft: CGFloat = 0
    ) {
        let width = CGFloat(columns) * cellSize
        let height = CGFloat(rows) * cellSize

        for c in 0...columns {
            let x = origin.x + CGFloat(c) * cellSize
            let major = c % 5 == 0 || c == columns
            var p = Path()
            p.move(to: CGPoint(x: x, y: origin.y - extendTop))
            p.addLine(to: CGPoint(x: x, y: origin.y + height))
            ctx.stroke(p, with: .color(major ? thick : thin), lineWidth: major ? 1.5 : 0.5)
        }
        for r in 0...rows {
            let y = origin.y + CGFloat(r) * cellSize
            let major = r % 5 == 0 || r == rows
            var p = Path()
            p.move(to: CGPoint(x: origin.x - extendLeft, y: y))
            p.addLine(to: CGPoint(x: origin.x + width, y: y))
            ctx.stroke(p, with: .color(major ? thick : thin), lineWidth: major ? 1.5 : 0.5)
        }
        ctx.stroke(
            Path(CGRect(x: origin.x, y: origin.y, width: width, height: height)),
            with: .color(thick), lineWidth: 2.5
        )
    }
}
