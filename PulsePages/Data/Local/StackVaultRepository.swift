import Foundation

@MainActor
final class StackVaultRepository: StackVaultGateway, ObservableObject {
    @Published private(set) var marks: [StackMark] = []
    private let defaults: UserDefaults
    private let storageKey = "pulse_pages_stack_v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        marks = Self.restore(defaults, key: storageKey)
    }

    @discardableResult
    func pinBook(_ book: PulseBook, note: String? = nil, rating: Int? = nil) -> StackPinResult {
        if let idx = marks.firstIndex(where: { $0.workKey == book.workKey }) {
            var row = marks[idx]
            row.headline = book.headline
            row.byline = book.byline
            if let note { row.journalNote = note }
            if let rating { row.pulseRating = clamp(rating) }
            marks.remove(at: idx)
            marks.insert(row, at: 0)
            save()
            return .refreshedPin
        }
        let row = StackMark(
            id: UUID(), workKey: book.workKey,
            headline: book.headline, byline: book.byline,
            pinnedAt: Date(), journalNote: note ?? "", pulseRating: rating.map(clamp)
        )
        marks.insert(row, at: 0)
        save()
        return .freshPin
    }

    func updateMark(workKey: String, note: String, rating: Int?) {
        guard let idx = marks.firstIndex(where: { $0.workKey == workKey }) else { return }
        var row = marks[idx]
        row.journalNote = note
        row.pulseRating = rating.map(clamp)
        marks.remove(at: idx)
        marks.insert(row, at: 0)
        save()
    }

    func removeMark(_ mark: StackMark) {
        marks.removeAll { $0.id == mark.id }
        save()
    }

    func isPinned(workKey: String) -> Bool {
        marks.contains { $0.workKey == workKey }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(marks) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func restore(_ defaults: UserDefaults, key: String) -> [StackMark] {
        guard let data = defaults.data(forKey: key),
              let rows = try? JSONDecoder().decode([StackMark].self, from: data) else { return [] }
        return rows
    }

    private func clamp(_ v: Int) -> Int { min(5, max(1, v)) }
}
