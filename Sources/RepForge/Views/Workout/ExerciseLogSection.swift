import SwiftUI
import SwiftData

struct ExerciseLogSection: View {
    @Bindable var loggedExercise: LoggedExercise

    @Environment(\.modelContext) private var context
    @ObservedObject private var restTimer = RestTimerManager.shared
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds = 90

    private var sortedSets: [LoggedSet] {
        loggedExercise.sets.sorted { $0.order < $1.order }
    }

    var body: some View {
        Section {
            if let exercise = loggedExercise.catalogExercise {
                NavigationLink(value: exercise) {
                    VStack(alignment: .leading) {
                        Text(exercise.name).font(.headline)
                        Text(exercise.bodyRegion).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            headerRow

            ForEach(sortedSets) { set in
                SetRow(set: set, setNumber: (sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1) {
                    toggleCompleted(set)
                }
            }
            .onDelete(perform: deleteSets)

            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus")
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("SET").frame(width: 40, alignment: .leading)
            Text("WEIGHT").frame(maxWidth: .infinity, alignment: .leading)
            Text("REPS").frame(maxWidth: .infinity, alignment: .leading)
            Text("").frame(width: 30)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private func addSet() {
        let nextOrder = (loggedExercise.sets.map(\.order).max() ?? -1) + 1
        let last = sortedSets.last
        let newSet = LoggedSet(reps: last?.reps ?? 8, weight: last?.weight ?? 0, order: nextOrder)
        context.insert(newSet)
        newSet.loggedExercise = loggedExercise
    }

    private func deleteSets(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sortedSets[index])
        }
    }

    private func toggleCompleted(_ set: LoggedSet) {
        set.isCompleted.toggle()
        if set.isCompleted {
            set.timestamp = Date()
            restTimer.start(seconds: defaultRestSeconds)
        }
    }
}

private struct SetRow: View {
    @Bindable var set: LoggedSet
    let setNumber: Int
    let onToggleComplete: () -> Void

    @ObservedObject private var units = UnitSettings.shared
    @State private var weightText: String = ""
    @State private var repsText: String = ""

    var body: some View {
        HStack {
            Text(set.isWarmup ? "W" : "\(setNumber)")
                .frame(width: 40, alignment: .leading)
                .foregroundStyle(set.isWarmup ? .orange : .primary)

            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: weightText) { _, newValue in
                    let displayed = Double(newValue) ?? 0
                    set.weight = units.unit.toPounds(displayed)
                }

            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: repsText) { _, newValue in
                    set.reps = Int(newValue) ?? 0
                }

            Button(action: onToggleComplete) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? Color.green : Color.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .frame(width: 30)
        }
        .onAppear {
            weightText = set.weight > 0 ? trimmed(units.unit.fromPounds(set.weight)) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }

    private func trimmed(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
