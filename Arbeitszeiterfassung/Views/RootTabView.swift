import SwiftUI

struct RootTabView: View {
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
