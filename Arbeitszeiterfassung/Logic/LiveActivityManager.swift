import ActivityKit
import Foundation

/// Steuert den Feierabend-Countdown auf Sperrbildschirm und Dynamic Island.
///
/// `sync` ist idempotent: Es startet die Activity, wenn der Tag läuft und noch
/// keine existiert, aktualisiert sie bei Zeitänderungen und beendet sie, wenn
/// der Tag vorbei ist oder das Feature ausgeschaltet wurde.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    func sync(day: WorkDay, enabled: Bool) async {
        guard enabled,
              !day.isFinished,
              Calendar.current.isDateInToday(day.date),
              ActivityAuthorizationInfo().areActivitiesEnabled
        else {
            await endAll()
            return
        }

        let state = WorkDayActivityAttributes.ContentState(
            startTime: day.startTime,
            plannedEnd: day.plannedEnd
        )
        let content = ActivityContent(state: state, staleDate: nil)

        if let activity = Activity<WorkDayActivityAttributes>.activities.first {
            await activity.update(content)
        } else {
            _ = try? Activity.request(
                attributes: WorkDayActivityAttributes(),
                content: content
            )
        }
    }

    func endAll() async {
        for activity in Activity<WorkDayActivityAttributes>.activities {
            await activity.end(activity.content, dismissalPolicy: .immediate)
        }
    }
}
