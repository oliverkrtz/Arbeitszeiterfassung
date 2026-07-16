import Foundation
import SwiftData

/// Ein erfasster Arbeitstag.
///
/// Sollzeit und Pause werden beim Anlegen aus den Einstellungen kopiert,
/// damit historische Tage stabil bleiben, wenn die Einstellungen später
/// geändert werden. Beides bleibt pro Tag editierbar.
@Model
final class WorkDay {
    @Attribute(.unique) var date: Date
    var startTime: Date
    var endTime: Date?
    var breakMinutes: Int
    var targetMinutes: Int

    init(date: Date, startTime: Date, endTime: Date? = nil, breakMinutes: Int, targetMinutes: Int) {
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = breakMinutes
        self.targetMinutes = targetMinutes
    }

    var isFinished: Bool { endTime != nil }

    /// Errechnete Feierabendzeit: Start + Sollarbeitszeit + Pause.
    var plannedEnd: Date {
        startTime.addingTimeInterval(TimeInterval((targetMinutes + breakMinutes) * 60))
    }

    /// Tatsächlich gearbeitete Minuten (ohne Pause), nur für beendete Tage.
    var workedMinutes: Int? {
        guard let endTime else { return nil }
        let gross = Int(endTime.timeIntervalSince(startTime) / 60)
        return gross - breakMinutes
    }

    /// Tagessaldo in Minuten (+ Überstunden / − Unterstunden), nur für beendete Tage.
    var balanceMinutes: Int? {
        guard let workedMinutes else { return nil }
        return workedMinutes - targetMinutes
    }
}
