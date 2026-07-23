import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.startDate,
        order: .reverse
    )
    private var sessions: [WorkoutSession]

    @ObservedObject private var units = UnitSettings.shared

    private struct WeekVolume: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volume: Double
    }

    private var weeklyVolumes: [WeekVolume] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.dateInterval(of: .weekOfYear, for: session.startDate)?.start ?? session.startDate
        }
        return grouped
            .map { WeekVolume(weekStart: $0.key, volume: $0.value.reduce(0) { $0 + $1.totalVolume }) }
            .sorted { $0.weekStart < $1.weekStart }
            .suffix(12)
            .map { $0 }
    }

    private var currentStreakWeeks: Int {
        let calendar = Calendar.current
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let weeksWithWorkouts = Set(sessions.map { calendar.dateInterval(of: .weekOfYear, for: $0.startDate)?.start ?? $0.startDate })

        var streak = 0
        var cursor = thisWeekStart
        while weeksWithWorkouts.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

    private var totalVolumeAllTime: Double {
        sessions.reduce(0) { $0 + $1.totalVolume }
    }

    var body: some View {
        List {
            Section {
                statRow(label: "Total Workouts", value: "\(sessions.count)")
                statRow(label: "Current Streak", value: "\(currentStreakWeeks) week\(currentStreakWeeks == 1 ? "" : "s")")
                statRow(label: "Lifetime Volume", value: units.display(totalVolumeAllTime))
            }

            if !weeklyVolumes.isEmpty {
                Section("Weekly Volume") {
                    Chart(weeklyVolumes) { week in
                        BarMark(
                            x: .value("Week", week.weekStart, unit: .weekOfYear),
                            y: .value("Volume", units.unit.fromPounds(week.volume))
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                    .frame(height: 200)
                }
            }

            Section("Units") {
                Picker("Weight Unit", selection: $units.rawUnit) {
                    ForEach(WeightUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.rawValue.uppercased()).tag(unit.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Stats")
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
