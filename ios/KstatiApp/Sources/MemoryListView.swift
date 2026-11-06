import SwiftUI
import UIKit
import MemoryCore

struct MemoryListView: View {
    @ObservedObject var store: MemoryStore
    @State private var query = ""
    @State private var adding = false
    @State private var managingGroups = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.search(query)) { item in
                    NavigationLink(value: item.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.confirmedText?.value ?? item.suggestion?.value ?? label(for: item))
                                .lineLimit(2)
                            Text(item.createdAt, style: .date)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("memoryItem_\(item.id.uuidString)")
                }
            }
            .overlay {
                if store.search(query).isEmpty {
                    ContentUnavailableView(query.isEmpty ? "Пока нет записей" : "Ничего не найдено",
                                           systemImage: "tray", description: Text(query.isEmpty ? "Сохраните первую заметку" : "Попробуйте другой запрос"))
                }
            }
            .navigationTitle("Память")
            .searchable(text: $query, prompt: "Поиск по подтверждённому тексту")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Группы", systemImage: "folder") { managingGroups = true }
                        .accessibilityIdentifier("manageGroups")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить", systemImage: "plus") { adding = true }
                        .accessibilityIdentifier("addMemory")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                MemoryDetailView(store: store, id: id)
            }
            .sheet(isPresented: $adding) { AddMemoryView(store: store) }
            .sheet(isPresented: $managingGroups) { GroupsView(store: store) }
            .alert("Ошибка", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("ОК") { store.error = nil }
            } message: { Text(store.error ?? "") }
            .onAppear { store.refresh() }
        }
    }

    private func label(for item: MemoryItem) -> String {
        switch item.original {
        case .text(let value): value
        case .image: "Изображение"
        }
    }
}
