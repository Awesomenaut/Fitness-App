import Foundation
import SwiftData

/// Tracks the in-progress workout session so any tab can resume it.
@MainActor
final class ActiveWorkoutStore: ObservableObject {
    @Published var activeSession: WorkoutSession?

    func start(in context: ModelContext) -> WorkoutSession {
        if let existing = activeSession {
            return existing
        }
        let session = WorkoutSession()
        context.insert(session)
        activeSession = session
        return session
    }

    func startFromRoutine(_ routine: Routine, in context: ModelContext) -> WorkoutSession {
        let session = start(in: context)
        for routineExercise in routine.exercises.sorted(by: { $0.order < $1.order }) {
            let logged = LoggedExercise(exerciseID: routineExercise.exerciseID, order: routineExercise.order)
            context.insert(logged)
            logged.session = session
            for setIndex in 0..<routineExercise.targetSets {
                let set = LoggedSet(reps: routineExercise.targetRepsLow, weight: 0, order: setIndex)
                context.insert(set)
                set.loggedExercise = logged
            }
        }
        return session
    }

    func finish() {
        activeSession?.endDate = Date()
        activeSession = nil
    }

    func discard(in context: ModelContext) {
        if let session = activeSession {
            context.delete(session)
        }
        activeSession = nil
    }
}
