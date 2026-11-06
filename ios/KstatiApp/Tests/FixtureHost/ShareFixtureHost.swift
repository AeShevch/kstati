import SwiftUI
import UIKit

@main
struct ShareFixtureHost: App {
    var body: some Scene {
        WindowGroup { FixtureView() }
    }
}

private struct FixtureView: View {
    @State private var sharing = false
    private let image: UIImage = {
        let original = UIImage(data: try! Data(contentsOf: Bundle.main.url(
            forResource: "appointment", withExtension: "png"
        )!))!
        guard ProcessInfo.processInfo.arguments.contains("-failureImage") else { return original }
        return UIGraphicsImageRenderer(size: original.size).image { renderer in
            original.draw(in: CGRect(origin: .zero, size: original.size))
            UIColor.red.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }()

    var body: some View {
        VStack(spacing: 24) {
            Image(uiImage: image).resizable().scaledToFit()
            Button("Поделиться снимком") { sharing = true }
                .accessibilityIdentifier("shareFixtureImage")
        }
        .padding()
        .sheet(isPresented: $sharing) { ActivitySheet(image: image) }
    }
}

private struct ActivitySheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
