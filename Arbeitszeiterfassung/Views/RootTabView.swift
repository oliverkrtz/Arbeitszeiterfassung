import SwiftUI

struct RootTabView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        TabView {
            Tab("Heute", systemImage: "sun.max") {
                TodayView()
            }
            Tab("Verlauf", systemImage: "calendar") {
                HistoryView()
            }
            Tab("Auswertung", systemImage: "chart.bar.xaxis") {
                StatsView()
            }
            Tab("Einstellungen", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    private var preferredScheme: ColorScheme? {
        switch settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Dezenter Farbverlauf als Hintergrund, damit die Glas-Flächen
/// etwas zum Brechen haben — bewusst zurückhaltend.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.14),
                Color(.systemBackground),
                Color.accentColor.opacity(0.06),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
