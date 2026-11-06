import SwiftUI
import UIKit
import MemoryCore

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
                    HStack {
                        Text(group.name).accessibilityIdentifier("group_\(group.id.uuidString)")
                        Spacer()
                        Button(role: .destructive) { store.deleteGroup(group.id) } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Удалить группу \(group.name)")
                        .buttonStyle(.borderless)
                    }
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
