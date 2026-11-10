#if DEBUG && targetEnvironment(simulator)
    import Foundation
    import MemoryCore

    enum MemoryAnalysisClient {
        struct Suggestion: Decodable {
            enum Kind: String, Decodable { case task, event }

            let kind: Kind
            let title: String
            let day: String?

            var plannerDay: PlannerDay? {
                guard let day, let key = Int(day.replacingOccurrences(of: "-", with: "")) else { return nil }
                let candidate = PlannerDay(key: key)
                guard let date = candidate.date(in: .gmt), PlannerDay(date, timeZone: .gmt) == candidate,
                    MemoryAnalysisClient.dayString(candidate) == day
                else { return nil }
                return candidate
            }

            var isValid: Bool {
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && title.unicodeScalars.count <= 200 && (day == nil || plannerDay != nil)
            }
        }

        private struct Request: Encodable {
            let text: String
            let today: String
        }

        private struct Response: Decodable {
            let suggestions: [Suggestion]
        }

        private final class NoRedirects: NSObject, URLSessionTaskDelegate {
            func urlSession(
                _ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void
            ) {
                completionHandler(nil)
            }
        }

        static func analyze(_ text: String) async throws -> [Suggestion] {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                text.unicodeScalars.count <= 4000,
                let url = URL(string: "http://localhost:48731/v1/memory-analysis")
            else { throw URLError(.badURL) }
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(Request(text: text, today: dayString(PlannerDay(.now))))
            let session = URLSession(configuration: .ephemeral, delegate: NoRedirects(), delegateQueue: nil)
            defer { session.finishTasksAndInvalidate() }
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 16_384 else {
                throw URLError(.badServerResponse)
            }
            let suggestions = try JSONDecoder().decode(Response.self, from: data).suggestions
            guard suggestions.count <= 5, suggestions.allSatisfy(\.isValid) else {
                throw URLError(.cannotDecodeContentData)
            }
            return suggestions
        }

        private static func dayString(_ day: PlannerDay) -> String {
            String(format: "%04d-%02d-%02d", day.key / 10000, day.key / 100 % 100, day.key % 100)
        }
    }
#endif
