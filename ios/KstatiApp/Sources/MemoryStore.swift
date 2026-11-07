import Foundation
import MemoryCore
import MemoryOCR
import MemoryPersistence
import SwiftUI

@MainActor
final class MemoryStore: ObservableObject {
    @Published var items: [MemoryItem] = []
    @Published var groups: [MemoryGroup] = []
    @Published var error: String?
    @Published private var drafts: [UUID: String] = [:]
    let repository: MemoryRepository?

    init() {
        do { repository = try SharedMemory.repository() } catch {
            repository = nil
            self.error = "Не удалось открыть локальное хранилище: \(error.localizedDescription)"
        }
        refresh()
    }

    func refresh() {
        guard let repository else { return }
        do {
            items = try repository.allItems()
            groups = try repository.allGroups()
        } catch { self.error = error.localizedDescription }
    }

    func saveText(_ value: String) -> Bool {
        guard let repository else { return false }
        do {
            try repository.saveText(value)
            refresh()
            return true
        } catch MemoryError.emptyText {
            error = "Нужен текст для сохранения"
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func search(_ query: String) -> [MemoryItem] {
        guard let repository, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return items }
        do { return try repository.search(query) } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    func confirm(_ value: String, itemID: UUID) {
        do {
            try repository?.confirmText(value, for: itemID)
            refresh()
        } catch { self.error = error.localizedDescription }
    }

    func draft(for id: UUID) -> String {
        if let draft = drafts[id] { return draft }
        let item = items.first { $0.id == id }
        return item?.confirmedText?.value ?? item?.suggestion?.value ?? ""
    }

    func setDraft(_ value: String, for id: UUID) {
        drafts[id] = value
    }

    func confirmDraft(for id: UUID) {
        confirm(draft(for: id), itemID: id)
    }

    func createGroup(_ name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            _ = try repository?.createGroup(name)
            refresh()
        } catch { self.error = error.localizedDescription }
    }

    func setMembership(itemID: UUID, groupID: UUID, enabled: Bool) {
        do {
            if enabled {
                try repository?.add(item: itemID, to: groupID)
            } else {
                try repository?.remove(item: itemID, from: groupID)
            }
            refresh()
        } catch { self.error = error.localizedDescription }
    }

    func deleteGroup(_ id: UUID) {
        do {
            try repository?.deleteGroup(id)
            refresh()
        } catch { self.error = error.localizedDescription }
    }

    func deleteItem(_ id: UUID) {
        do {
            try repository?.deleteItem(id)
            refresh()
        } catch { self.error = error.localizedDescription }
    }

    func runOCRIfNeeded(_ item: MemoryItem) {
        guard item.kind == .image, item.suggestion == nil, let repository else { return }
        let id = item.id
        Task.detached(priority: .utility) {
            do {
                try OCRProcessor(recognizer: VisionTextRecognizer()).process(id, repository: repository)
                await MainActor.run { self.refresh() }
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
        }
    }
}
