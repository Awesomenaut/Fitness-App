import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    let exercise: Exercise

    @Query private var loggedInstances: [LoggedExercise]
    @ObservedObject private var units = UnitSettings.shared

    init(exercise: Exercise) {
        self.exercise = exercise
        let targetID = exercise.id
        _loggedInstances = Query(filter: #Predicate<LoggedExercise> { $0.exerciseID == targetID })
    }

    private struct HistoryPoint: Identifiable {
        let id = UUID()
        let date: Date
        let estimatedOneRepMax: Double
        let volume: Double
    }

    private var points: [HistoryPoint] {
        loggedInstances
            .compactMap { logged -> HistoryPoint? in
                let completedSets = logged.sets.filter { $0.isCompleted && !$0.isWarmup }
                guard let best = completedSets.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }) else {
                    return nil
                }
                let volume = completedSets.reduce(0) { $0 + $1.weight * Double($1.reps) }
                let date = logged.session?.startDate ?? best.timestamp
                return HistoryPoint(date: date, estimatedOneRepMax: best.estimatedOneRepMax, volume: volume)
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            if points.count > 1 {
                Section("Estimated 1RM Trend") {
                    Chart(points) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("1RM", units.unit.fromPounds(point.estimatedOneRepMax))
                        )
                        .symbol(.circle)
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 200)
                }
            }

            Section("Sessions") {
                ForEach(points.reversed()) { point in
                    HStack {
                        Text(point.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("Best ~\(units.display(point.estimatedOneRepMax)) 1RM")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if points.isEmpty {
                ContentUnavailableView("No History Yet", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}
