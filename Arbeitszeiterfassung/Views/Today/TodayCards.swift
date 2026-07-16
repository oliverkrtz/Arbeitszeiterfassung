import SwiftUI
import SwiftData

// MARK: - Noch kein Eintrag

struct StartDayCard: View {
    @Binding var plannedStart: Date
    let settings: AppSettings
    let glassNamespace: Namespace.ID
    let onStart: () -> Void

    private var previewEnd: Date {
        plannedStart.addingTimeInterval(
            TimeInterval((settings.targetMinutes + settings.breakMinutes) * 60)
        )
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sunrise")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 8)

            Text("Guten Morgen")
                .font(.title2.weight(.semibold))

            DatePicker(
                "Startzeit",
                selection: $plannedStart,
                displayedComponents: .hourAndMinute
            )
            .font(.body)

            HStack {
                Text("Feierabend wäre um")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(previewEnd.formatted(date: .omitted, time: .shortened))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.callout)

            Button(action: onStart) {
                Label("Arbeitstag starten", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .glassEffectID("todayCard", in: glassNamespace)
    }
}

// MARK: - Tag läuft

struct RunningDayCard: View {
    @Bindable var day: WorkDay
    let glassNamespace: Namespace.ID
    let onFinish: () -> Void
    let onTimesChanged: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.everyMinute) { timeline in
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Feierabend um")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(day.plannedEnd.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 52, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }

                    ProgressRing(progress: progress(at: timeline.date)) {
                        VStack(spacing: 2) {
                            Text(remainingLabel(at: timeline.date))
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            Text(remainingCaption(at: timeline.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                DatePicker(
                    "Startzeit",
                    selection: $day.startTime,
                    displayedComponents: .hourAndMinute
                )
                Stepper(value: $day.breakMinutes, in: 0...120, step: 5) {
                    HStack {
                        Text("Pause")
                        Spacer()
                        Text("\(day.breakMinutes) Min")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .font(.callout)
            .onChange(of: day.startTime) { onTimesChanged() }
            .onChange(of: day.breakMinutes) { onTimesChanged() }

            Button(action: onFinish) {
                Label("Feierabend machen", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .glassEffectID("todayCard", in: glassNamespace)
    }

    private func progress(at now: Date) -> Double {
        let total = Double((day.targetMinutes + day.breakMinutes) * 60)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(day.startTime)
        return min(max(elapsed / total, 0), 1)
    }

    private func remainingMinutes(at now: Date) -> Int {
        Int(day.plannedEnd.timeIntervalSince(now) / 60)
    }

    private func remainingLabel(at now: Date) -> String {
        let remaining = remainingMinutes(at: now)
        return WorkDayCalculator.durationString(minutes: abs(remaining))
    }

    private func remainingCaption(at now: Date) -> String {
        remainingMinutes(at: now) >= 0 ? "verbleibend" : "über der Zeit"
    }
}

// MARK: - Tag beendet

struct FinishedDayCard: View {
    let day: WorkDay
    let totalBalance: Int
    let glassNamespace: Namespace.ID
    let onResume: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 8)

            Text("Feierabend")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                SummaryRow(label: "Start", value: day.startTime.formatted(date: .omitted, time: .shortened))
                if let endTime = day.endTime {
                    SummaryRow(label: "Ende", value: endTime.formatted(date: .omitted, time: .shortened))
                }
                SummaryRow(label: "Pause", value: "\(day.breakMinutes) Min")
                if let worked = day.workedMinutes {
                    SummaryRow(label: "Gearbeitet", value: WorkDayCalculator.durationString(minutes: worked))
                }
            }
            .font(.callout)

            Divider()

            if let balance = day.balanceMinutes {
                HStack {
                    Text("Tagessaldo")
                    Spacer()
                    BalanceText(minutes: balance)
                }
                .font(.callout.weight(.medium))
            }

            HStack {
                Text("Gleitzeitkonto")
                    .foregroundStyle(.secondary)
                Spacer()
                BalanceText(minutes: totalBalance)
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)

            Button(action: onResume) {
                Label("Weiter arbeiten", systemImage: "arrow.uturn.backward")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .glassEffectID("todayCard", in: glassNamespace)
    }
}

// MARK: - Bausteine

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
    }
}

/// Saldo-Anzeige mit gedeckten Farben: Grün für plus, Rot für minus.
struct BalanceText: View {
    let minutes: Int

    var body: some View {
        Text(WorkDayCalculator.balanceString(minutes: minutes))
            .monospacedDigit()
            .foregroundStyle(minutes >= 0 ? Color.green : Color.red)
    }
}

struct ProgressRing<Center: View>: View {
    let progress: Double
    @ViewBuilder let center: Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth, value: progress)
            center
        }
        .frame(width: 150, height: 150)
    }
}
