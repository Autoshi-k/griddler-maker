import GriddlerCore
import SwiftUI

struct ControlsSidebar: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Form {
            Section("Image") {
                if let preview = model.originalPreview {
                    Image(decorative: preview, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                HStack {
                    Button(model.hasImage ? "Replace…" : "Open…") { model.isImporterPresented = true }
                    Spacer()
                    Button("Clear", role: .destructive) { model.clear() }
                        .disabled(!model.hasImage)
                }
            }

            Section {
                LabeledSlider("Hue", value: $model.adjustments.hue, in: -180...180, step: 1) { "\(Int($0))°" }
                LabeledSlider("Saturation", value: $model.adjustments.saturation, in: 0...5, step: 0.05) {
                    $0.formatted(.number.precision(.fractionLength(2)))
                }
                LabeledSlider("Gamma", value: $model.adjustments.gamma, in: 0.1...3, step: 0.05) {
                    $0.formatted(.number.precision(.fractionLength(2)))
                }
                Toggle("Invert", isOn: $model.adjustments.invert)
            } header: {
                SectionHeader("Color") {
                    model.adjustments = .identity
                }
                .resetDisabled(model.adjustments.isIdentity)
            }
            .disabled(!model.hasImage)

            Section {
                LabeledSlider(
                    "Columns",
                    value: Binding(get: { Double(model.columns) }, set: { model.columns = Int($0.rounded()) }),
                    in: Double(GriddlerModel.columnRange.lowerBound)...Double(GriddlerModel.columnRange.upperBound),
                    step: 1
                ) { "\(Int($0))" }
                LabeledContent("Rows", value: "\(model.rows)")
                LabeledSlider("Threshold", value: $model.threshold, in: 0...1, step: 0.01) {
                    $0.formatted(.number.precision(.fractionLength(2)))
                }
                Text("Blocks darker than the threshold become filled cells.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Grid")
            }
            .disabled(!model.hasImage)

            if model.grid != nil {
                Section("Puzzle") {
                    PuzzleStatusView()
                    if !model.overrides.isEmpty {
                        LabeledContent("Hand-painted cells", value: "\(model.overrides.count)")
                        Button("Discard Edits") { model.discardEdits() }
                    }
                }
            }

            Section("Display") {
                LabeledSlider("Cell Size", value: $model.cellSize, in: 10...40, step: 1) { "\(Int($0)) pt" }
            }
            .disabled(!model.hasImage)
        }
        .formStyle(.grouped)
    }
}

private struct PuzzleStatusView: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        if let grid = model.grid {
            let ratio = Double(grid.filledCount) / Double(max(1, grid.filled.count))
            LabeledContent("Size", value: "\(grid.columns) × \(grid.rows)")
            LabeledContent("Filled", value: ratio.formatted(.percent.precision(.fractionLength(0))))
        }
        if let report = model.solveReport {
            if report.isSolved {
                Label("Solvable by logic alone", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else if report.contradiction {
                Label("Clues are inconsistent", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(report.unresolvedCount) cells can’t be deduced", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Solvers would have to guess, or the clues fit more than one picture. Paint cells in the Grid view (unresolved cells are highlighted) or tweak the threshold.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    init(
        _ title: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double,
        format: @escaping (Double) -> String
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
                .labelsHidden()
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let onReset: () -> Void
    private var resetDisabled = false

    init(_ title: String, onReset: @escaping () -> Void) {
        self.title = title
        self.onReset = onReset
    }

    func resetDisabled(_ disabled: Bool) -> Self {
        var copy = self
        copy.resetDisabled = disabled
        return copy
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button("Reset", action: onReset)
                .buttonStyle(.link)
                .font(.caption)
                .disabled(resetDisabled)
        }
    }
}
