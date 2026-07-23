import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @State private var showingNewRoutine = false

    var body: some View {
        List {
            ForEach(routines) { routine in
                NavigationLink(value: routine) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name).font(.headline)
                        Text("\(routine.exercises.count) exercises")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteRoutines)
        }
        .overlay {
            if routines.isEmpty {
                ContentUnavailableView(
                    "No Routines Yet",
                    systemImage: "square.stack.3d.up",
                    description: Text("Build a routine to speed up starting your workouts.")
                )
            }
        }
        .navigationTitle("Routines")
        .navigationDestination(for: Routine.self) { routine in
            RoutineEditorView(routine: routine)
        }
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    let routine = Routine(name: "New Routine")
                    context.insert(routine)
                    showingNewRoutine = true
                    newlyCreated = routine
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(isPresented: $showingNewRoutine) {
            if let newlyCreated {
                RoutineEditorView(routine: newlyCreated)
            }
        }
    }

    @State private var newlyCreated: Routine?

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            context.delete(routines[index])
        }
    }
}
