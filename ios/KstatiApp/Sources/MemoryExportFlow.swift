import MemoryPersistence
import SwiftUI

struct MemoryExportFlow: ViewModifier {
    let repository: MemoryRepository?

    @Binding var result: String?

    @Binding var requested: Bool
    @State private var preparing = false
    @State private var presenting = false
    @State private var archive: URL?

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Экспорт памяти", isPresented: $requested, titleVisibility: .visible) {
                Button("Подготовить архив") { prepare() }
                    .disabled(preparing || presenting || repository == nil)
            } message: {
                Text("Архив содержит ваши записи, группы и исходные вложения.")
            }
            .fileExporter(
                isPresented: $presenting,
                document: archive.map { MemoryExportFile(url: $0) },
                contentTypes: [.zip],
                defaultFilename: "Кстати",
                onCompletion: { outcome in
                    switch outcome {
                    case .success: finish(message: "Архив сохранён.")
                    case .failure: finish(message: "Не удалось сохранить архив. Попробуйте ещё раз.")
                    }
                },
                onCancellation: { finish(message: nil) }
            )
    }

    private func prepare() {
        guard let repository else { return }
        preparing = true
        let workspace = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        Task {
            defer { preparing = false }
            do {
                archive = try await Task.detached {
                    try MemoryArchiveExport.prepare(from: repository, in: workspace)
                }.value
                presenting = true
            } catch {
                result = "Не удалось подготовить архив. Попробуйте ещё раз."
            }
        }
    }

    private func finish(message: String?) {
        guard let archive else { return }
        self.archive = nil
        do {
            try FileManager.default.removeItem(at: archive.deletingLastPathComponent())
            result = message
        } catch {
            result = [message, "Не удалось удалить временный архив."].compactMap { $0 }.joined(separator: " ")
        }
    }
}
