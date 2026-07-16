import ActivityKit
import SwiftUI
import WidgetKit

/// Countdown bis Feierabend als Live Activity: Sperrbildschirm + Dynamic Island.
struct WorkDayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkDayActivityAttributes.self) { context in
            LockScreenCountdownView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Feierabend", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.plannedEnd.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(timerInterval: context.state.startTime...context.state.plannedEnd, countsDown: true)
                            .font(.title.weight(.semibold))
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                        CountdownProgressBar(state: context.state)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text(timerInterval: context.state.startTime...context.state.plannedEnd, countsDown: true)
                    .monospacedDigit()
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
            }
        }
    }
}

/// Dezente Sperrbildschirm-Karte: Feierabendzeit, laufender Countdown,
/// Fortschrittsbalken — alles system-getrieben, keine Updates nötig.
struct LockScreenCountdownView: View {
    let state: WorkDayActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(
                    "Feierabend um \(state.plannedEnd.formatted(date: .omitted, time: .shortened))",
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                Spacer()
                Text(timerInterval: state.startTime...state.plannedEnd, countsDown: true)
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .frame(maxWidth: 88, alignment: .trailing)
            }
            CountdownProgressBar(state: state)
        }
        .padding(16)
        .activityBackgroundTint(nil)
    }
}

struct CountdownProgressBar: View {
    let state: WorkDayActivityAttributes.ContentState

    var body: some View {
        ProgressView(
            timerInterval: state.startTime...state.plannedEnd,
            countsDown: false,
            label: { EmptyView() },
            currentValueLabel: { EmptyView() }
        )
        .progressViewStyle(.linear)
        .tint(.orange)
    }
}
