import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Bindable var routine: Routine

    @Environment(\.modelContext) private var context
    @State private var showingExercisePicker = false

    private var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Routine name", text: $routine.name)
            }

            Section("Exercises") {
                ForEach(sortedExercises) { routineExercise in
                    RoutineExerciseRow(routineExercise: routineExercise)
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExerciseListView(selectionMode: true) { exercise in
                    addExercise(exercise)
                }
            }
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let order = (routine.exercises.map(\.order).max() ?? -1) + 1
        let routineExercise = RoutineExercise(exerciseID: exercise.id, order: order)
        context.insert(routineExercise)
        routineExercise.routine = routine
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sortedExercises[index])
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var reordered = sortedExercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            item.order = index
        }
    }
}

private struct RoutineExerciseRow: View {
    @Bindable var routineExercise: RoutineExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(routineExercise.catalogExercise?.name ?? "Unknown Exercise")
                .font(.headline)

            HStack {
                Stepper("Sets: \(routineExercise.targetSets)", value: $routineExercise.targetSets, in: 1...10)
            }
            .font(.subheadline)

            HStack(spacing: 12) {
                Text("Reps")
                Stepper("\(routineExercise.targetRepsLow)", value: $routineExercise.targetRepsLow, in: 1...50)
                Text("to")
                Stepper("\(routineExercise.targetRepsHigh)", value: $routineExercise.targetRepsHigh, in: 1...50)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
