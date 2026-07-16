import ActivityKit
import Foundation

/// Gemeinsame Definition der Live Activity — wird in App UND Widget-Extension
/// kompiliert; ActivityKit ordnet beide über Typnamen und Struktur einander zu.
struct WorkDayActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Startzeit des laufenden Arbeitstags.
        var startTime: Date
        /// Errechnete Feierabendzeit (Start + Sollzeit + Pause).
        var plannedEnd: Date
    }
}
