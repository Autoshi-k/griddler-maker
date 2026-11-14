import SwiftUI

struct ContentView: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            ControlsSidebar()
                .navigationSplitViewColumnWidth(min: 270, ideal: 300, max: 380)
        } detail: {
            Group {
                if !model.hasImage {
                    EmptyStateView()
                } else {
                    switch model.stage {
                    case .source: SourceStageView()
                    case .grid: GridStageView()
                    case .puzzle: PuzzleStageView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(model.imageName ?? "Griddler Maker")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Stage", selection: $model.stage) {
                    ForEach(GriddlerModel.Stage.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(!model.hasImage)
            }
            ToolbarItem {
                if model.isProcessing { ProgressView().controlSize(.small) }
            }
            ToolbarItem {
                Button { model.isImporterPresented = true } label: {
                    Label("Open Image", systemImage: "photo.badge.plus")
                }
                .help("Open an image (⌘O)")
            }
            ToolbarItem {
                Menu {
                    Button("Export Puzzle…") { Exporter.export(model, solution: false) }
                    Button("Export Solution…") { Exporter.export(model, solution: true) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(model.grid == nil)
                .help("Export the puzzle as PNG")
            }
        }
        .fileImporter(isPresented: $model.isImporterPresented, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url): model.load(url: url)
            case .failure(let error): model.errorMessage = error.localizedDescription
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            model.load(url: url)
            return true
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } }),
            presenting: model.errorMessage
        ) { _ in
            Button("OK") {}
        } message: { Text($0) }
    }
}

private struct EmptyStateView: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        ContentUnavailableView {
            Label("Drop an Image Here", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Pick a picture with a clear subject. It will be turned black & white and split into a grid of cells.")
        } actions: {
            Button("Choose Image…") { model.isImporterPresented = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

/// A view area that centers its content and scrolls when it doesn't fit.
struct CenteredScrollView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView([.horizontal, .vertical]) {
                content
                    .padding(28)
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}
