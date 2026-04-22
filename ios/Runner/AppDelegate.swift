import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let workoutLiveActivityChannel = "it.fitgenius.gigi/workout_live_activity"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configureWorkoutLiveActivityChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureWorkoutLiveActivityChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: workoutLiveActivityChannel,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "updateWorkoutActivity":
        guard let payload = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Missing workout payload", details: nil))
          return
        }
        self.updateWorkoutActivity(payload: payload)
        result(nil)
      case "endWorkoutActivity":
        self.endWorkoutActivity()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func updateWorkoutActivity(payload: [String: Any]) {
    guard #available(iOS 16.2, *) else { return }

    let workoutName = payload["workoutName"] as? String ?? "Allenamento"
    let state = WorkoutActivityAttributes.ContentState(
      currentExerciseName: payload["currentExerciseName"] as? String ?? "Allenamento",
      currentSetNumber: payload["currentSetNumber"] as? Int ?? 1,
      currentSetTotal: payload["currentSetTotal"] as? Int ?? 1,
      currentTargetReps: payload["currentTargetReps"] as? String,
      currentMuscleGroups: payload["currentMuscleGroups"] as? [String] ?? [],
      currentSecondaryMuscleGroups: payload["currentSecondaryMuscleGroups"] as? [String] ?? [],
      nextExerciseName: payload["nextExerciseName"] as? String,
      nextSetNumber: payload["nextSetNumber"] as? Int,
      nextSetTotal: payload["nextSetTotal"] as? Int,
      nextTargetReps: payload["nextTargetReps"] as? String,
      isResting: payload["isResting"] as? Bool ?? false,
      restRemainingSeconds: payload["restRemainingSeconds"] as? Int,
      restTotalSeconds: payload["restTotalSeconds"] as? Int,
      restEndsAtMillis: (payload["restEndsAtMillis"] as? Int) ?? (payload["restEndsAt"] as? Int),
      restCompleted: payload["restCompleted"] as? Bool ?? false,
      totalExercises: max(payload["totalExercises"] as? Int ?? 1, 1),
      currentExerciseIndex: max(payload["currentExerciseIndex"] as? Int ?? 0, 0)
    )

    Task {
      if let activity = Activity<WorkoutActivityAttributes>.activities.first {
        await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)))
        return
      }

      do {
        let attributes = WorkoutActivityAttributes(workoutName: workoutName)
        _ = try Activity.request(
          attributes: attributes,
          content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(15 * 60)),
          pushType: nil
        )
      } catch {
        debugPrint("Unable to start workout Live Activity: \(error)")
      }
    }
  }

  private func endWorkoutActivity() {
    guard #available(iOS 16.2, *) else { return }

    Task {
      for activity in Activity<WorkoutActivityAttributes>.activities {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
    }
  }
}
