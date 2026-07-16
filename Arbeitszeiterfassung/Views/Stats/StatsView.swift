import SwiftUI
import SwiftData
import Charts

enum StatsPeriod: String, CaseIterable, Identifiable {
    case week = "7 Tage"
    case month = "30 Tage"
    case all = "Gesamt"

    var id: String { rawValue }

    var startDate: Date? {
        switch self {
        case .week: Calendar.current.date(byAdding: .day, value: -7, to: .now)
        case .month: Calendar.current.date(byAdding: .day, value: -30, to: .now)
        case .all: nil
        }
    }
}

struct StatsView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkDay.date) private var days: [WorkDay]

    @State private var period: StatsPeriod = .month

    /// Abgeschlossene Tage im gewählten Zeitraum, chronologisch.
    private var finishedDays: [WorkDay] {
        days.filter { day in
            guard day.isFinished else { return false }
            guard let start = period.startDate else { return true }
            return day.date >= start
        }
    }

    /// Der Gesamtsaldo ist bewusst zeitraumunabhängig — ein Konto hat einen Stand.
    private var totalBalance: Int {
        WorkDayCalculator.totalBalanceMinutes(
            days: days,
            startBalanceMinutes: settings.startBalanceMinutes
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Zeitraum", selection: $period) {
                            ForEach(StatsPeriod.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        if finishedDays.isEmpty {
                            ContentUnavailableView(
                                "Noch keine Daten",
                                systemImage: "chart.bar",
                                description: Text("Sobald abgeschlossene Arbeitstage im Zeitraum liegen, erscheinen hier deine Auswertungen.")
                            )
                            .padding(.top, 60)
                        } else {
                            GlassEffectContainer(spacing: 16) {
                                VStack(spacing: 16) {
                                    statTiles
                                    BalanceChartCard(days: finishedDays)
                                    TimesChartCard(days: finishedDays)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Auswertung")
        }
    }

    private var statTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatTile(title: "Ø Startzeit", value: averageClock(of: finishedDays.map(\.startTime)))
            StatTile(title: "Ø Feierabend", value: averageClock(of: finishedDays.compactMap(\.endTime)))
            StatTile(title: "Ø Arbeitszeit", value: averageDuration)
            StatTile(title: "Gleitzeitkonto", value: WorkDayCalculator.balanceString(minutes: totalBalance),
                     valueColor: totalBalance >= 0 ? .green : .red)
        }
    }

    private func averageClock(of dates: [Date]) -> String {
        guard let minute = WorkDayCalculator.averageMinuteOfDay(of: dates) else { return "–" }
        return WorkDayCalculator.clockString(minuteOfDay: minute)
    }

    private var averageDuration: String {
        let worked = finishedDays.compactMap(\.workedMinutes)
        guard !worked.isEmpty else { return "–" }
        return WorkDayCalculator.durationString(minutes: worked.reduce(0, +) / worked.count)
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
