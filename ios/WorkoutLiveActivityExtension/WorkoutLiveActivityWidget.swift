import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.05, blue: 0.06))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Set \(context.state.currentSetNumber)/\(context.state.currentSetTotal)")
                        .font(.caption.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isResting ? restLabel(context.state.restRemainingSeconds) : "GIGI")
                        .font(.caption.weight(.bold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentExerciseName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
            } compactLeading: {
                Text("\(context.state.currentSetNumber)/\(context.state.currentSetTotal)")
                    .font(.caption2.weight(.bold))
            } compactTrailing: {
                Text(context.state.isResting ? restLabel(context.state.restRemainingSeconds) : "G")
                    .font(.caption2.weight(.bold))
            } minimal: {
                Text("\(context.state.currentSetNumber)")
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private func restLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "Rec" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

private struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            MiniAnatomyView(
                primaryMuscles: context.state.currentMuscleGroups,
                secondaryMuscles: context.state.currentSecondaryMuscleGroups
            )
            .frame(width: 72, height: 112)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(context.attributes.workoutName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    if context.state.isResting {
                        Text(restLabel(context.state.restRemainingSeconds))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.1))
                            .monospacedDigit()
                    }
                }

                Text(context.state.currentExerciseName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    metric("Set", "\(context.state.currentSetNumber)/\(context.state.currentSetTotal)")
                    if let reps = context.state.currentTargetReps, !reps.isEmpty {
                        metric("Reps", reps)
                    }
                }

                Divider().overlay(.white.opacity(0.16))

                HStack(spacing: 6) {
                    Image(systemName: "forward.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                    Text(nextLine)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
    }

    private var nextLine: String {
        guard let name = context.state.nextExerciseName,
              let set = context.state.nextSetNumber,
              let total = context.state.nextSetTotal else {
            return "Prossima: fine allenamento"
        }

        let reps = context.state.nextTargetReps.flatMap { $0.isEmpty ? nil : " • \($0) reps" } ?? ""
        return "Prossima: \(name) • Set \(set)/\(total)\(reps)"
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.42))
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
    }

    private func restLabel(_ seconds: Int?) -> String {
        guard let seconds else { return "Recupero" }
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

private struct MiniAnatomyView: View {
    let primaryMuscles: [String]
    let secondaryMuscles: [String]

    private let primary = Color(red: 0.93, green: 0.12, blue: 0.12)
    private let secondary = Color(red: 1.0, green: 0.55, blue: 0.55)
    private let base = Color.white.opacity(0.22)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.06))
            VStack(spacing: 2) {
                Circle().fill(base).frame(width: 16, height: 16)
                ZStack {
                    Capsule().fill(color(for: ["chest", "petto", "back", "schiena", "core", "abs", "addome"])).frame(width: 24, height: 38)
                    HStack(spacing: 30) {
                        Capsule().fill(color(for: ["shoulders", "spalle", "arms", "biceps", "triceps", "braccia"])).frame(width: 8, height: 40)
                        Capsule().fill(color(for: ["shoulders", "spalle", "arms", "biceps", "triceps", "braccia"])).frame(width: 8, height: 40)
                    }
                    VStack {
                        Spacer()
                        Capsule().fill(color(for: ["abs", "core", "addome"])).frame(width: 18, height: 18)
                    }
                }
                HStack(spacing: 8) {
                    Capsule().fill(color(for: ["legs", "quad", "hamstrings", "glutes", "gambe", "glutei", "calves", "polpacci"])).frame(width: 10, height: 42)
                    Capsule().fill(color(for: ["legs", "quad", "hamstrings", "glutes", "gambe", "glutei", "calves", "polpacci"])).frame(width: 10, height: 42)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func color(for tokens: [String]) -> Color {
        if contains(tokens, in: primaryMuscles) { return primary }
        if contains(tokens, in: secondaryMuscles) { return secondary }
        return base
    }

    private func contains(_ tokens: [String], in muscles: [String]) -> Bool {
        let normalized = muscles.map { $0.lowercased() }
        return normalized.contains { muscle in
            tokens.contains { token in muscle.contains(token) }
        }
    }
}

@main
struct WorkoutLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
