import SwiftUI
import Charts

/// Tagessaldo als Balken um die Nulllinie. Die Richtung ist über die Position
/// (über/unter null) codiert, die Farbe nur redundant dazu.
struct BalanceChartCard: View {
    let days: [WorkDay]

    private struct Entry: Identifiable {
        let id: Date
        let date: Date
        let balanceHours: Double
    }

    private var entries: [Entry] {
        days.compactMap { day in
            guard let balance = day.balanceMinutes else { return nil }
            return Entry(id: day.date, date: day.date, balanceHours: Double(balance) / 60)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tagessaldo")
                .font(.headline)

            Chart {
                ForEach(entries) { entry in
                    BarMark(
                        x: .value("Tag", entry.date, unit: .day),
                        y: .value("Saldo", entry.balanceHours)
                    )
                    .foregroundStyle(entry.balanceHours >= 0 ? Color.green.opacity(0.75) : Color.red.opacity(0.75))
                    .cornerRadius(4)
                }

                RuleMark(y: .value("Null", 0))
                    .foregroundStyle(.quaternary)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hours = value.as(Double.self) {
                            Text(String(format: "%+.1f h", hours))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}

/// Start- und Feierabendzeiten im Zeitverlauf als Punktdiagramm.
/// Blau/Orange als farbfehlsichtigkeits-sicheres Paar, Identität zusätzlich
/// über die Legende.
struct TimesChartCard: View {
    let days: [WorkDay]

    private struct Entry: Identifiable {
        let id: String
        let date: Date
        let hour: Double
        let kind: String
    }

    private var entries: [Entry] {
        days.flatMap { day -> [Entry] in
            var result = [Entry(
                id: "start-\(day.date.timeIntervalSince1970)",
                date: day.date,
                hour: WorkDayCalculator.hourValue(of: day.startTime),
                kind: "Start"
            )]
            if let end = day.endTime {
                result.append(Entry(
                    id: "ende-\(day.date.timeIntervalSince1970)",
                    date: day.date,
                    hour: WorkDayCalculator.hourValue(of: end),
                    kind: "Feierabend"
                ))
            }
            return result
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start & Feierabend")
                .font(.headline)

            Chart(entries) { entry in
                PointMark(
                    x: .value("Tag", entry.date, unit: .day),
                    y: .value("Uhrzeit", entry.hour)
                )
                .foregroundStyle(by: .value("Art", entry.kind))
                .symbolSize(60)
            }
            .chartForegroundStyleScale([
                "Start": Color.blue,
                "Feierabend": Color.orange,
            ])
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let hour = value.as(Double.self) {
                            Text(String(format: "%02d:00", Int(hour)))
                        }
                    }
                }
            }
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 220)
        }
        .padding(20)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }
}
