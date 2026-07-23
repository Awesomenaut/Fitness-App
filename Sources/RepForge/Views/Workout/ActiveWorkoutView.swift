import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeWorkout: ActiveWorkoutStore
    @ObservedObject private var restTimer = RestTimerManager.shared
    @ObservedObject private var units = UnitSettings.shared

    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingDiscardConfirm = false
    @State private var elapsedTimerTick = Date()

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header

            if restTimer.isRunning {
                RestTimerBanner()
            }

            List {
                ForEach(session.exercises.sorted(by: { $0.order < $1.order })) { loggedExercise in
                    ExerciseLogSection(loggedExercise: loggedExercise)
                }
                .onDelete(perform: deleteExercises)

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Active Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard", role: .destructive) { showingDiscardConfirm = true }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Finish") { showingFinishConfirm = true }
                    .disabled(session.completedSetCount == 0)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExerciseListView(selectionMode: true) { exercise in
                    addExercise(exercise)
                }
            }
        }
        .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirm, titleVisibility: .visible) {
            Button("Finish") { activeWorkout.finish() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Discard this workout?", isPresented: $showingDiscardConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { activeWorkout.discard(in: context) }
            Button("Cancel", role: .cancel) {}
        }
        .onReceive(clockTimer) { elapsedTimerTick = $0 }
        .onAppear { restTimer.requestNotificationPermission() }
    }

    private var header: some View {
        HStack {
            Label(formattedElapsed, systemImage: "timer")
            Spacer()
            Text("\(units.display(session.totalVolume)) volume")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var formattedElapsed: String {
        let seconds = Int(elapsedTimerTick.timeIntervalSince(session.startDate))
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func addExercise(_ exercise: Exercise) {
        let order = (session.exercises.map(\.order).max() ?? -1) + 1
        let logged = LoggedExercise(exerciseID: exercise.id, order: order)
        context.insert(logged)
        logged.session = session
        let firstSet = LoggedSet()
        context.insert(firstSet)
        firstSet.loggedExercise = logged
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = session.exercises.sorted(by: { $0.order < $1.order })
        for index in offsets {
            context.delete(sorted[index])
        }
    }
}

private struct RestTimerBanner: View {
    @ObservedObject private var restTimer = RestTimerManager.shared

    var body: some View {
        HStack {
            Image(systemName: "timer")
            Text("Rest: \(restTimer.remainingSeconds)s")
                .font(.headline)
            Spacer()
            Button("-15s") { restTimer.addSeconds(-15) }
            Button("+15s") { restTimer.addSeconds(15) }
            Button("Skip") { restTimer.cancel() }
        }
        .font(.subheadline)
        .padding()
        .background(Color.accentColor.opacity(0.15))
    }
}
