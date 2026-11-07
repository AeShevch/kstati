import MemoryCore
import SwiftUI
import UIKit

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
                        if store.saveText(text) {
                            dismiss()
                        } else {
                            validationMessage = store.error ?? "Не удалось сохранить"
                            store.error = nil
                        }
                    }
                    .accessibilityIdentifier("saveMemory")
                }
            }
            .alert(
                "Не удалось сохранить",
                isPresented: Binding(
                    get: { validationMessage != nil },
                    set: { if !$0 { validationMessage = nil } }
                )
            ) {
                Button("ОК") { validationMessage = nil }
            } message: {
                Text(validationMessage ?? "")
            }
        }
    }
}
