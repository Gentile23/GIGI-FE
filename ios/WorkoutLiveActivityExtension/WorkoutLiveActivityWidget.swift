import ActivityKit
import Foundation
import SwiftUI
import UIKit
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
                    restStatusView(for: context.state, fallback: "GIGI")
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
                restStatusView(for: context.state, fallback: "G")
            } minimal: {
                Text("\(context.state.currentSetNumber)")
                    .font(.caption2.weight(.bold))
            }
        }
    }

    @ViewBuilder
    private func restStatusView(
        for state: WorkoutActivityAttributes.ContentState,
        fallback: String
    ) -> some View {
        if state.restCompleted {
            Text("FINITO")
                .font(.caption2.weight(.bold))
        } else if state.isResting, let endsAt = state.restEndsAt, endsAt > Date() {
            Text(timerInterval: Date()...endsAt, countsDown: true)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
        } else if state.isResting {
            Text("0:00")
                .font(.caption2.weight(.bold))
                .monospacedDigit()
        } else {
            Text(fallback)
                .font(.caption2.weight(.bold))
        }
    }
}

private struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    private var totalExercises: Int {
        max(context.state.totalExercises, 1)
    }

    private var currentExerciseIndex: Int {
        min(max(context.state.currentExerciseIndex, 0), totalExercises - 1)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Session Progress Circle
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(currentExerciseIndex + 1) / CGFloat(totalExercises))
                    .stroke(
                        LinearGradient(colors: [.accentColor, .blue], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: -2) {
                    Text("\(currentExerciseIndex + 1)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("/\(totalExercises)")
                        .font(.system(size: 10, weight: .medium))
                        .opacity(0.6)
                }
            }
            .frame(width: 52, height: 52)
            .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 6) {
                // Header: Workout Name & Timer
                HStack(alignment: .firstTextBaseline) {
                    Text(context.attributes.workoutName.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if context.state.restCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("PRONTO")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.green)
                    } else if context.state.isResting, let endsAt = context.state.restEndsAt, endsAt > Date() {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(timerInterval: Date()...endsAt, countsDown: true)
                                .monospacedDigit()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.orange)
                    }
                }

                // Exercise Name
                Text(context.state.currentExerciseName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Metrics Row
                HStack(spacing: 10) {
                    metricBadge(systemName: "number.square.fill", value: "SET \(context.state.currentSetNumber)/\(context.state.currentSetTotal)")
                    
                    if let reps = context.state.currentTargetReps, !reps.isEmpty {
                        metricBadge(systemName: "repeat", value: "\(reps) REPS")
                    }
                    
                    Spacer()
                }
                
                // Next Up
                if let next = context.state.nextExerciseName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 10))
                        Text("PROSSIMO: \(next.uppercased())")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 2)
                }
            }
        }
        .padding(16)
    }

    private func metricBadge(systemName: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.1), in: Capsule())
        .foregroundStyle(.white)
    }
}

private extension WorkoutActivityAttributes.ContentState {
    var restEndsAt: Date? {
        guard let restEndsAtMillis else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(restEndsAtMillis) / 1000)
    }
}

@main
struct WorkoutLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivityWidget()
    }
}
