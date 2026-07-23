import Foundation

/// Static exercise reference data, bundled read-only in the app (not a SwiftData model).
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let level: String
    let mechanic: String?
    let force: String?
    let equipment: String
    let bodyRegion: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]

    var muscleSummary: String {
        primaryMuscles.joined(separator: ", ")
    }
}

enum BodyRegion: String, CaseIterable, Identifiable {
    case all = "All"
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case legs = "Legs"
    case other = "Other"

    var id: String { rawValue }
}
