import Foundation

/// Loads the bundled exercise library once and serves lookups to the rest of the app.
/// Immutable after init, so it's safe to read from any isolation context (including
/// the nonisolated `catalogExercise` computed properties on the SwiftData models).
final class ExerciseCatalog: Sendable {
    static let shared = ExerciseCatalog()

    let all: [Exercise]
    private let byID: [String: Exercise]

    private init() {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            assertionFailure("exercises.json missing from bundle")
            all = []
            byID = [:]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Exercise].self, from: data)
            all = decoded.sorted { $0.name < $1.name }
            byID = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
        } catch {
            assertionFailure("Failed to decode exercises.json: \(error)")
            all = []
            byID = [:]
        }
    }

    func exercise(id: String) -> Exercise? {
        byID[id]
    }

    var equipmentTypes: [String] {
        Array(Set(all.map(\.equipment))).sorted()
    }
}
