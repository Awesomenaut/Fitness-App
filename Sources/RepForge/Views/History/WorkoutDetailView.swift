import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let session: WorkoutSession

    @ObservedObject private var units = UnitSettings.shared

    private var sortedExercises: [LoggedExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section {
                summaryRow(label: "Date", value: session.startDate.formatted(date: .abbreviated, time: .shortened))
                summaryRow(label: "Duration", value: formattedDuration)
                summaryRow(label: "Total Volume", value: units.display(session.totalVolume))
                summaryRow(label: "Sets Completed", value: "\(session.completedSetCount)")
            }

            ForEach(sortedExercises) { loggedExercise in
                Section(loggedExercise.catalogExercise?.name ?? "Exercise") {
                    ForEach(loggedExercise.sets.sorted(by: { $0.order < $1.order })) { set in
                        HStack {
                            Text(set.isWarmup ? "Warm-up" : "Set \(set.order + 1)")
                                .foregroundStyle(set.isWarmup ? .orange : .primary)
                            Spacer()
                            Text("\(units.display(set.weight)) × \(set.reps)")
                            if set.isCompleted {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .font(.subheadline)
                    }
                    if let exercise = loggedExercise.catalogExercise {
                        NavigationLink("View Exercise", value: exercise)
                            .font(.caption)
                    }
                }
            }

            if !session.notes.isEmpty {
                Section("Notes") {
                    Text(session.notes)
                }
            }
        }
        .navigationTitle("Workout Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        return "\(minutes) min"
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
        }
    }
}
