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

struct AddMemoryView: View {
    @ObservedObject var store: MemoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextEditor(text: $text).frame(minHeight: 160)
                    .accessibilityIdentifier("newMemoryText")
            }
            .navigationTitle("Новая запись")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if store.saveText(text) { dismiss() }
                        else { validationMessage = store.error ?? "Не удалось сохранить"; store.error = nil }
                    }
                        .accessibilityIdentifier("saveMemory")
                }
            }
            .alert("Не удалось сохранить", isPresented: Binding(
                get: { validationMessage != nil },
                set: { if !$0 { validationMessage = nil } }
            )) { Button("ОК") { validationMessage = nil } }
            message: { Text(validationMessage ?? "") }
        }
    }
}

struct MemoryDetailView: View {
    @ObservedObject var store: MemoryStore
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var editedText = ""
    @State private var deleting = false

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
                    TextEditor(text: $editedText).frame(minHeight: 110)
                        .accessibilityIdentifier("confirmedTextEditor")
                    Button("Сохранить текст") { store.confirm(editedText, itemID: id) }
                        .accessibilityIdentifier("confirmText")
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
            if let item {
                editedText = item.confirmedText?.value ?? item.suggestion?.value ?? ""
                store.runOCRIfNeeded(item)
            }
        }
        .onChange(of: item?.suggestion?.value) { _, value in
            if editedText.isEmpty { editedText = value ?? "" }
        }
        .confirmationDialog("Удалить запись и оригинал?", isPresented: $deleting) {
            Button("Удалить", role: .destructive) { store.deleteItem(id); dismiss() }
        }
    }
}

struct GroupsView: View {
    @ObservedObject var store: MemoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    TextField("Название группы", text: $newName)
                        .accessibilityIdentifier("newGroupName")
                    Button("Создать") { store.createGroup(newName); newName = "" }
                }
                ForEach(store.groups) { group in
                    Text(group.name).accessibilityIdentifier("group_\(group.id.uuidString)")
                }
                .onDelete { offsets in
                    for index in offsets { store.deleteGroup(store.groups[index].id) }
                }
            }
            .navigationTitle("Группы")
            .toolbar { Button("Готово") { dismiss() } }
        }
    }
}
