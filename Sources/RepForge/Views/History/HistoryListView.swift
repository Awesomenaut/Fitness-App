import SwiftUI
import SwiftData

struct HistoryListView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.startDate,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    @Environment(\.modelContext) private var context
    @ObservedObject private var units = UnitSettings.shared

    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink(value: session) {
                    row(for: session)
                }
            }
            .onDelete(perform: deleteSessions)
        }
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Workouts Logged",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Finish a workout to see it here.")
                )
            }
        }
        .navigationTitle("History")
        .navigationDestination(for: WorkoutSession.self) { session in
            WorkoutDetailView(session: session)
        }
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }

    private func row(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            Text("\(session.exercises.count) exercises · \(session.completedSetCount) sets · \(units.display(session.totalVolume))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
    }
}
