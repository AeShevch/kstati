import SwiftUI
import UIKit
import MemoryCore

struct MemoryDetailView: View {
    @ObservedObject var store: MemoryStore
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var deleting = false
    @State private var editorRevision = 0
    @FocusState private var isEditingText: Bool

    private var item: MemoryItem? { store.items.first { $0.id == id } }

    var body: some View {
        Form {
            if let item {
                Section("Оригинал") {
                    switch item.original {
                    case .text(let value): Text(value).accessibilityIdentifier("originalText")
                    case .image:
                        if let data = try? store.repository?.originalData(for: id),
                           let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFit()
                                .accessibilityIdentifier("originalImage")
                        } else { Text("Не удалось открыть оригинал") }
                    }
                }
                if let suggestion = item.suggestion?.value {
                    Section("Предложение OCR") { Text(suggestion).accessibilityIdentifier("ocrSuggestion") }
                }
                Section("Подтверждённый текст или описание") {
                    TextField("Текст", text: Binding(
                        get: { store.draft(for: id) },
                        set: { store.setDraft($0, for: id) }
                    ), axis: .vertical)
                        .lineLimit(3...8)
                        .accessibilityIdentifier("confirmedTextEditor")
                        .focused($isEditingText)
                        .id(editorRevision)
                    HStack {
                        Button("Очистить") {
                            isEditingText = false
                            store.setDraft("", for: id)
                            editorRevision += 1
                        }
                            .accessibilityIdentifier("clearConfirmedText")
                        .buttonStyle(.borderless)
                        Spacer()
                        Button("Сохранить текст") {
                            store.confirmDraft(for: id)
                            isEditingText = false
                        }
                        .accessibilityIdentifier("confirmText")
                        .buttonStyle(.borderless)
                    }
                }
                Section("Группы") {
                    ForEach(store.groups) { group in
                        Toggle(group.name, isOn: Binding(
                            get: { (try? store.repository?.groups(for: id).contains(group)) ?? false },
                            set: { store.setMembership(itemID: id, groupID: group.id, enabled: $0) }
                        ))
                    }
                }
                Section {
                    Button("Удалить запись", role: .destructive) { deleting = true }
                }
            }
        }
        .navigationTitle("Запись")
        .onAppear {
            if let item { store.runOCRIfNeeded(item) }
        }
        .onChange(of: item?.suggestion?.value) { _, value in
            if store.draft(for: id).isEmpty { store.setDraft(value ?? "", for: id) }
        }
        .confirmationDialog("Удалить запись и оригинал?", isPresented: $deleting) {
            Button("Удалить", role: .destructive) { store.deleteItem(id); dismiss() }
        }
    }
}
