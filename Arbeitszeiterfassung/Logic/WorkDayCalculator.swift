import Foundation

/// Reine Rechen- und Formatierlogik, ohne UI- oder Persistenz-Abhängigkeiten.
enum WorkDayCalculator {

    // MARK: - Saldo

    /// Gesamtsaldo des Gleitzeitkontos: Startsaldo + Summe aller Tagessalden
    /// abgeschlossener Tage. Laufende Tage zählen noch nicht.
    static func totalBalanceMinutes(days: [WorkDay], startBalanceMinutes: Int) -> Int {
        startBalanceMinutes + days.compactMap(\.balanceMinutes).reduce(0, +)
    }

    // MARK: - Durchschnitte

    /// Durchschnittliche Uhrzeit (Minuten seit Mitternacht) einer Menge von Zeitpunkten.
    static func averageMinuteOfDay(of dates: [Date]) -> Int? {
        guard !dates.isEmpty else { return nil }
        let calendar = Calendar.current
        let total = dates.reduce(0) { sum, date in
            let comps = calendar.dateComponents([.hour, .minute], from: date)
            return sum + (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        }
        return total / dates.count
    }

    /// Uhrzeit eines Zeitpunkts als Stunden-Dezimalwert (z. B. 7,5 für 07:30) — für Diagramm-Achsen.
    static func hourValue(of date: Date) -> Double {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60
    }

    // MARK: - Formatierung

    /// Minuten seit Mitternacht als Uhrzeit, z. B. "07:42".
    static func clockString(minuteOfDay: Int) -> String {
        String(format: "%02d:%02d", minuteOfDay / 60, minuteOfDay % 60)
    }

    /// Dauer in Minuten als "7:45 h".
    static func durationString(minutes: Int) -> String {
        let m = abs(minutes)
        return String(format: "%d:%02d h", m / 60, m % 60)
    }

    /// Saldo in Minuten mit Vorzeichen, z. B. "+1:15" oder "−0:30".
    static func balanceString(minutes: Int) -> String {
        let sign = minutes < 0 ? "−" : "+"
        let m = abs(minutes)
        return String(format: "%@%d:%02d", sign, m / 60, m % 60)
    }
}
