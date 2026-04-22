import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentExerciseName: String
        var currentSetNumber: Int
        var currentSetTotal: Int
        var currentTargetReps: String?
        var currentMuscleGroups: [String]
        var currentSecondaryMuscleGroups: [String]
        var nextExerciseName: String?
        var nextSetNumber: Int?
        var nextSetTotal: Int?
        var nextTargetReps: String?
        var isResting: Bool
        var restRemainingSeconds: Int?
        var restTotalSeconds: Int?
        var restEndsAtMillis: Int?
        var restCompleted: Bool
        var bodyImageBase64: String?
    }

    var workoutName: String
}
