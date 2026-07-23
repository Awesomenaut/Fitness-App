import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeWorkout: ActiveWorkoutStore
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    var body: some View {
        Group {
            if let session = activeWorkout.activeSession {
                ActiveWorkoutView(session: session)
            } else {
                startScreen
            }
        }
        .navigationTitle("Workout")
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    private var startScreen: some View {
        List {
            Section {
                Button {
                    _ = activeWorkout.start(in: context)
                } label: {
                    Label("Start Empty Workout", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }

            if !routines.isEmpty {
                Section("Your Routines") {
                    ForEach(routines) { routine in
                        Button {
                            _ = activeWorkout.startFromRoutine(routine, in: context)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.name).font(.headline)
                                Text("\(routine.exercises.count) exercises")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
