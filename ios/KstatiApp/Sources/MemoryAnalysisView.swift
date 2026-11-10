#if DEBUG && targetEnvironment(simulator)
    import MemoryCore
    import SwiftUI

    struct MemoryAnalysisView: View {
        let store: MemoryStore
        let sourceID: UUID
        let snapshot: ConfirmedText

        @Environment(\.dismiss) private var dismiss
        @State private var request: Task<Void, Never>?
        @State private var suggestions: [MemoryAnalysisClient.Suggestion]?
        @State private var error: String?
        @State private var accepted: Set<Int> = []

        var body: some View {
            List {
                Section("Текст для анализа") {
                    Text(snapshot.value).accessibilityIdentifier("analysisPreview")
                    Text("Этот текст получит локальный тестовый сервис, чтобы предложить задачи или события.")
                    Button("Отправить текст") { send() }
                        .accessibilityIdentifier("confirmAnalysis")
                        .disabled(request != nil || snapshot.value.unicodeScalars.count > 4000)
                    if snapshot.value.unicodeScalars.count > 4000 {
                        Text("Для анализа доступно до 4000 символов.")
                    }
                }
                if request != nil { ProgressView("Анализ…") }
                if let error { Text(error).accessibilityIdentifier("analysisError") }
                if let suggestions {
                    Section("Предложения") {
                        if suggestions.isEmpty { Text("Предложений нет") }
                        ForEach(suggestions.indices, id: \.self) { index in
                            if !accepted.contains(index) {
                                suggestionLink(suggestions[index], index: index)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Анализ записи")
            .toolbar {
                Button("Закрыть") { dismiss() }.accessibilityIdentifier("closeAnalysis")
            }
            .onDisappear {
                request?.cancel()
                request = nil
            }
        }

        private func suggestionLink(_ suggestion: MemoryAnalysisClient.Suggestion, index: Int) -> some View {
            NavigationLink {
                PlannerEditor(
                    store: store, suggestedTitle: suggestion.title, suggestedEvent: suggestion.kind == .event,
                    suggestedDay: suggestion.plannerDay
                ) { title, schedule in
                    guard let repository = store.repository,
                        try repository.item(id: sourceID)?.confirmedText == snapshot
                    else { throw MemoryError.missingItem }
                    try repository.createPlan(title: title, sourceID: sourceID, schedule: schedule)
                    accepted.insert(index)
                }
            } label: {
                Label(suggestion.title, systemImage: suggestion.kind == .event ? "calendar" : "checkmark.circle")
            }
            .accessibilityIdentifier("analysisSuggestion-\(index)")
        }

        private func send() {
            guard request == nil else { return }
            error = nil
            suggestions = nil
            accepted = []
            request = Task {
                do {
                    guard let repository = store.repository,
                        try repository.item(id: sourceID)?.confirmedText == snapshot
                    else {
                        error = "Текст изменился. Откройте анализ заново."
                        request = nil
                        return
                    }
                    let result = try await MemoryAnalysisClient.analyze(snapshot.value)
                    try Task.checkCancellation()
                    guard try repository.item(id: sourceID)?.confirmedText == snapshot else {
                        error = "Текст изменился. Откройте анализ заново."
                        request = nil
                        return
                    }
                    suggestions = result
                } catch {
                    guard !Task.isCancelled else { return }
                    self.error = "Не удалось выполнить анализ. Проверьте локальный сервис и повторите отправку."
                }
                request = nil
            }
        }
    }
#endif
