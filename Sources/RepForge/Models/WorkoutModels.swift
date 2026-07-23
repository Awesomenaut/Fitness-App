import Foundation
import SwiftData

/// A single completed (or in-progress) workout session.
@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise] = []

    init(startDate: Date = Date()) {
        self.id = UUID()
        self.startDate = startDate
    }

    var isActive: Bool { endDate == nil }

    var duration: TimeInterval {
        (endDate ?? Date()).timeIntervalSince(startDate)
    }

    /// Total volume in pounds (reps * weight across all completed sets).
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter(\.isCompleted).reduce(0) { $0 + $1.weight * Double($1.reps) }
        }
    }

    var completedSetCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
    }
}

/// One exercise performed within a workout session, holding its ordered sets.
@Model
final class LoggedExercise {
    var id: UUID = UUID()
    var exerciseID: String = ""
    var order: Int = 0
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var sets: [LoggedSet] = []

    init(exerciseID: String, order: Int) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.order = order
    }

    var catalogExercise: Exercise? {
        ExerciseCatalog.shared.exercise(id: exerciseID)
    }
}

/// A single working (or warm-up) set: weight is always stored in pounds.
@Model
final class LoggedSet {
    var id: UUID = UUID()
    var order: Int = 0
    var reps: Int = 0
    var weight: Double = 0
    var rpe: Double?
    var isWarmup: Bool = false
    var isCompleted: Bool = false
    var timestamp: Date = Date()
    var loggedExercise: LoggedExercise?

    init(reps: Int = 0, weight: Double = 0, isWarmup: Bool = false, order: Int = 0) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.isWarmup = isWarmup
        self.order = order
    }

    var estimatedOneRepMax: Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        // Epley formula
        return weight * (1 + Double(reps) / 30.0)
    }
}

/// A user-defined, reusable workout template.
@Model
final class Routine {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

/// One planned exercise slot within a routine.
@Model
final class RoutineExercise {
    var id: UUID = UUID()
    var exerciseID: String = ""
    var order: Int = 0
    var targetSets: Int = 3
    var targetRepsLow: Int = 8
    var targetRepsHigh: Int = 12
    var routine: Routine?

    init(exerciseID: String, order: Int, targetSets: Int = 3, targetRepsLow: Int = 8, targetRepsHigh: Int = 12) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.order = order
        self.targetSets = targetSets
        self.targetRepsLow = targetRepsLow
        self.targetRepsHigh = targetRepsHigh
    }

    var catalogExercise: Exercise? {
        ExerciseCatalog.shared.exercise(id: exerciseID)
    }
}
