import AppKit
import SwiftUI

@main
struct GriddlerMakerApp: App {
    @State private var model = GriddlerModel()

    init() {
        // Needed when launched via `swift run` (no app bundle) so we get a Dock icon and menu bar.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("Griddler Maker", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 960, minHeight: 620)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    // `swift run GriddlerMaker path/to/image.jpg` opens that image.
                    if let path = CommandLine.arguments.dropFirst().first(where: { !$0.hasPrefix("-") }),
                       FileManager.default.fileExists(atPath: path) {
                        model.load(url: URL(fileURLWithPath: path))
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Image…") { model.isImporterPresented = true }
                    .keyboardShortcut("o")
            }
            CommandGroup(after: .saveItem) {
                Button("Export Puzzle…") { Exporter.export(model, solution: false) }
                    .keyboardShortcut("e")
                    .disabled(model.grid == nil)
                Button("Export Solution…") { Exporter.export(model, solution: true) }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    .disabled(model.grid == nil)
            }
        }
    }
}
