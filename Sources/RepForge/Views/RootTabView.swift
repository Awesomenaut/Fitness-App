import SwiftUI

struct RootTabView: View {
    @StateObject private var activeWorkout = ActiveWorkoutStore()

    var body: some View {
        TabView {
            NavigationStack {
                WorkoutHomeView()
            }
            .tabItem { Label("Workout", systemImage: "figure.strengthtraining.traditional") }

            NavigationStack {
                ExerciseListView(selectionMode: false, onSelect: nil)
            }
            .tabItem { Label("Exercises", systemImage: "list.bullet") }

            NavigationStack {
                RoutineListView()
            }
            .tabItem { Label("Routines", systemImage: "square.stack.3d.up") }

            NavigationStack {
                HistoryListView()
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            NavigationStack {
                StatsView()
            }
            .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .environmentObject(activeWorkout)
    }
}
