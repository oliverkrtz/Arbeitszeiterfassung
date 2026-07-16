import Foundation
import UserNotifications

/// Plant und storniert die lokale Feierabend-Benachrichtigung.
///
/// Pro Tag werden feste Identifier verwendet, dadurch ist Umplanen idempotent:
/// erneutes Planen ersetzt die bestehende Benachrichtigung.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private func endIdentifier(for day: WorkDay) -> String {
        "feierabend-\(dayKey(day))"
    }

    private func preAlertIdentifier(for day: WorkDay) -> String {
        "feierabend-vorwarnung-\(dayKey(day))"
    }

    private func dayKey(_ day: WorkDay) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: day.date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    /// Fragt die Berechtigung an (beim ersten Mal zeigt iOS den System-Dialog).
    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Plant die Feierabend-Benachrichtigung (und optional eine Vorwarnung)
    /// für die errechnete Feierabendzeit des Tages. Ersetzt bestehende Planungen.
    func scheduleEndOfWork(for day: WorkDay, preAlertMinutes: Int) async {
        cancel(for: day)

        guard await requestAuthorization() else { return }

        let center = UNUserNotificationCenter.current()
        let plannedEnd = day.plannedEnd

        if plannedEnd > .now {
            let content = UNMutableNotificationContent()
            content.title = "Feierabend! 🎉"
            content.body = "Deine Sollarbeitszeit ist erreicht. Zeit, Schluss zu machen."
            content.sound = .default
            try? await center.add(UNNotificationRequest(
                identifier: endIdentifier(for: day),
                content: content,
                trigger: calendarTrigger(for: plannedEnd)
            ))
        }

        if preAlertMinutes > 0 {
            let preAlertDate = plannedEnd.addingTimeInterval(TimeInterval(-preAlertMinutes * 60))
            if preAlertDate > .now {
                let content = UNMutableNotificationContent()
                content.title = "Gleich Feierabend"
                content.body = "Noch \(preAlertMinutes) Minuten bis zum Feierabend."
                content.sound = .default
                try? await center.add(UNNotificationRequest(
                    identifier: preAlertIdentifier(for: day),
                    content: content,
                    trigger: calendarTrigger(for: preAlertDate)
                ))
            }
        }
    }

    /// Storniert alle geplanten Benachrichtigungen des Tages
    /// (z. B. wenn vor der Sollzeit gestempelt wird).
    func cancel(for day: WorkDay) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [endIdentifier(for: day), preAlertIdentifier(for: day)]
        )
    }

    private func calendarTrigger(for date: Date) -> UNCalendarNotificationTrigger {
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        return UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    }
}
