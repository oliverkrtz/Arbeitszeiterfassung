import Foundation
import Observation

/// Erscheinungsbild der App.
enum Appearance: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }
}

/// App-Einstellungen, persistiert in UserDefaults.
@Observable
final class AppSettings {
    private static let targetKey = "settings.targetMinutes"
    private static let breakKey = "settings.breakMinutes"
    private static let startBalanceKey = "settings.startBalanceMinutes"
    private static let notificationsKey = "settings.notificationsEnabled"
    private static let preAlertKey = "settings.preAlertMinutes"
    private static let appearanceKey = "settings.appearance"

    /// Sollarbeitszeit pro Tag in Minuten (Default: 8 Stunden).
    var targetMinutes: Int {
        didSet { UserDefaults.standard.set(targetMinutes, forKey: Self.targetKey) }
    }

    /// Pausendauer pro Tag in Minuten (Default: 45, gesetzeskonform bei 8 h).
    var breakMinutes: Int {
        didSet { UserDefaults.standard.set(breakMinutes, forKey: Self.breakKey) }
    }

    /// Startsaldo des Gleitzeitkontos in Minuten (kann negativ sein).
    var startBalanceMinutes: Int {
        didSet { UserDefaults.standard.set(startBalanceMinutes, forKey: Self.startBalanceKey) }
    }

    /// Feierabend-Benachrichtigung aktiv?
    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Self.notificationsKey) }
    }

    /// Zusätzliche Vorwarnung X Minuten vor Feierabend (0 = aus).
    var preAlertMinutes: Int {
        didSet { UserDefaults.standard.set(preAlertMinutes, forKey: Self.preAlertKey) }
    }

    /// Erscheinungsbild: System, Hell oder Dunkel.
    var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Self.targetKey: 8 * 60,
            Self.breakKey: 45,
            Self.startBalanceKey: 0,
            Self.notificationsKey: true,
            Self.preAlertKey: 0,
            Self.appearanceKey: Appearance.system.rawValue,
        ])
        targetMinutes = defaults.integer(forKey: Self.targetKey)
        breakMinutes = defaults.integer(forKey: Self.breakKey)
        startBalanceMinutes = defaults.integer(forKey: Self.startBalanceKey)
        notificationsEnabled = defaults.bool(forKey: Self.notificationsKey)
        preAlertMinutes = defaults.integer(forKey: Self.preAlertKey)
        appearance = Appearance(rawValue: defaults.integer(forKey: Self.appearanceKey)) ?? .system
    }
}
