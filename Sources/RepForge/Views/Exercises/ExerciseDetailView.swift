import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Query private var loggedInstances: [LoggedExercise]

    init(exercise: Exercise) {
        self.exercise = exercise
        let targetID = exercise.id
        _loggedInstances = Query(filter: #Predicate<LoggedExercise> { $0.exerciseID == targetID })
    }

    private var personalRecord: LoggedSet? {
        loggedInstances
            .flatMap(\.sets)
            .filter { $0.isCompleted && !$0.isWarmup }
            .max { $0.estimatedOneRepMax < $1.estimatedOneRepMax }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let pr = personalRecord {
                    PRCard(set: pr)
                }

                infoGrid

                if !exercise.secondaryMuscles.isEmpty {
                    labeledSection(title: "Secondary Muscles", text: exercise.secondaryMuscles.joined(separator: ", "))
                }

                if !exercise.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Instructions").font(.headline)
                        ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(Color.accentColor))
                                Text(step).font(.body)
                            }
                        }
                    }
                }

                if !loggedInstances.isEmpty {
                    NavigationLink("View Full History") {
                        ExerciseHistoryView(exercise: exercise)
                    }
                    .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.name).font(.title2.weight(.bold))
            Text(exercise.muscleSummary).foregroundStyle(.secondary)
        }
    }

    private var infoGrid: some View {
        HStack {
            InfoPill(label: "Equipment", value: exercise.equipment)
            InfoPill(label: "Level", value: exercise.level.capitalized)
            if let mechanic = exercise.mechanic {
                InfoPill(label: "Mechanic", value: mechanic.capitalized)
            }
        }
    }

    private func labeledSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).foregroundStyle(.secondary)
        }
    }
}

private struct InfoPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct PRCard: View {
    let set: LoggedSet
    @ObservedObject private var units = UnitSettings.shared

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill").foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text("Personal Record").font(.caption).foregroundStyle(.secondary)
                Text("\(units.display(set.weight)) × \(set.reps) reps")
                    .font(.headline)
            }
            Spacer()
            Text("~\(units.display(set.estimatedOneRepMax)) 1RM")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
