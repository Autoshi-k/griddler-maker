import SwiftUI

/// Overview of every pipeline step, side by side.
struct SourceStageView: View {
    @Environment(GriddlerModel.self) private var model

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ImagePane(title: "Original", image: model.originalPreview)
                ImagePane(title: "Color Adjusted", image: model.adjustedPreview)
            }
            HStack(spacing: 16) {
                ImagePane(title: "Black & White", image: model.grayscalePreview)
                ImagePane(title: "Pixelated", image: model.gridPreview, pixelated: true) {
                    Button("Edit Grid") { model.stage = .grid }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}

private struct ImagePane<Accessory: View>: View {
    let title: String
    let image: CGImage?
    var pixelated = false
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image {
                    Image(decorative: image, scale: 1)
                        .interpolation(pixelated ? .none : .high)
                        .resizable()
                        .scaledToFit()
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text(title).font(.headline)
                Spacer()
                accessory
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }
}

extension ImagePane where Accessory == EmptyView {
    init(title: String, image: CGImage?, pixelated: Bool = false) {
        self.init(title: title, image: image, pixelated: pixelated) { EmptyView() }
    }
}
