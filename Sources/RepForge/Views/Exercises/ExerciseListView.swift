import SwiftUI

/// Browsable exercise library. When `selectionMode` is true, tapping an exercise
/// calls `onSelect` and dismisses instead of pushing the detail view — used when
/// adding an exercise to an in-progress workout or routine.
struct ExerciseListView: View {
    var selectionMode: Bool
    var onSelect: ((Exercise) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var region: BodyRegion = .all
    @State private var equipment: String = "All"

    private let catalog = ExerciseCatalog.shared

    private var equipmentOptions: [String] {
        ["All"] + catalog.equipmentTypes
    }

    private var filtered: [Exercise] {
        catalog.all.filter { exercise in
            let matchesRegion = region == .all || exercise.bodyRegion == region.rawValue
            let matchesEquipment = equipment == "All" || exercise.equipment == equipment
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryMuscles.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesRegion && matchesEquipment && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            List(filtered) { exercise in
                if selectionMode {
                    Button {
                        onSelect?(exercise)
                        dismiss()
                    } label: {
                        ExerciseRow(exercise: exercise)
                    }
                    .foregroundStyle(.primary)
                } else {
                    NavigationLink(value: exercise) {
                        ExerciseRow(exercise: exercise)
                    }
                }
            }
            .listStyle(.plain)
        }
        .searchable(text: $searchText, prompt: "Search exercises or muscles")
        .navigationTitle("Exercises")
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BodyRegion.allCases) { r in
                        FilterChip(title: r.rawValue, isSelected: region == r) { region = r }
                    }
                }
                .padding(.horizontal)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(equipmentOptions, id: \.self) { eq in
                        FilterChip(title: eq, isSelected: equipment == eq) { equipment = eq }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name).font(.body.weight(.medium))
            Text("\(exercise.bodyRegion) · \(exercise.equipment)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
