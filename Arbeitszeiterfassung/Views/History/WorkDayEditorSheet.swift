import SwiftUI
import SwiftData

/// Bearbeitet einen bestehenden Tag. Änderungen wirken direkt auf das Model
/// (SwiftData speichert automatisch); läuft der heutige Tag noch, wird die
/// Feierabend-Benachrichtigung beim Schließen neu geplant.
struct WorkDayEditorSheet: View {
    @Bindable var day: WorkDay
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeiten") {
                    DatePicker("Start", selection: $day.startTime, displayedComponents: .hourAndMinute)
                    if day.endTime != nil {
                        DatePicker("Ende", selection: endBinding, displayedComponents: .hourAndMinute)
                        Button("Ende entfernen", role: .destructive) {
                            day.endTime = nil
                        }
                    } else {
                        Button("Endzeit setzen") {
                            day.endTime = defaultEnd
                        }
                    }
                }

                Section("Tageswerte") {
                    Stepper(value: $day.breakMinutes, in: 0...120, step: 5) {
                        LabeledContent("Pause", value: "\(day.breakMinutes) Min")
                    }
                    Stepper(value: $day.targetMinutes, in: 0...16 * 60, step: 15) {
                        LabeledContent("Sollzeit", value: WorkDayCalculator.durationString(minutes: day.targetMinutes))
                    }
                }

                if let balance = day.balanceMinutes {
                    Section {
                        LabeledContent("Tagessaldo") {
                            BalanceText(minutes: balance)
                        }
                    }
                }
            }
            .navigationTitle(day.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onDisappear {
                rescheduleIfNeeded()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var endBinding: Binding<Date> {
        Binding(
            get: { day.endTime ?? defaultEnd },
            set: { day.endTime = $0 }
        )
    }

    private var defaultEnd: Date { day.plannedEnd }

    private func rescheduleIfNeeded() {
        guard Calendar.current.isDateInToday(day.date) else { return }

        let liveActivityEnabled = settings.liveActivityEnabled
        Task { await LiveActivityManager.shared.sync(day: day, enabled: liveActivityEnabled) }

        if day.isFinished || !settings.notificationsEnabled {
            NotificationManager.shared.cancel(for: day)
        } else {
            let preAlert = settings.preAlertMinutes
            Task {
                await NotificationManager.shared.scheduleEndOfWork(for: day, preAlertMinutes: preAlert)
            }
        }
    }
}

/// Trägt einen vergessenen Tag nach.
struct AddWorkDaySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query private var days: [WorkDay]

    @State private var date: Date = .now
    @State private var startTime: Date = .now
    @State private var endTime: Date = .now
    @State private var breakMinutes: Int = 0
    @State private var targetMinutes: Int = 0
    @State private var showsDuplicateAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag") {
                    DatePicker("Datum", selection: $date, in: ...Date.now, displayedComponents: .date)
                }
                Section("Zeiten") {
                    DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("Ende", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                Section("Tageswerte") {
                    Stepper(value: $breakMinutes, in: 0...120, step: 5) {
                        LabeledContent("Pause", value: "\(breakMinutes) Min")
                    }
                    Stepper(value: $targetMinutes, in: 0...16 * 60, step: 15) {
                        LabeledContent("Sollzeit", value: WorkDayCalculator.durationString(minutes: targetMinutes))
                    }
                }
            }
            .navigationTitle("Tag nachtragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(!isValid)
                }
            }
            .alert("Eintrag existiert bereits", isPresented: $showsDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Für diesen Tag gibt es schon einen Eintrag. Bearbeite ihn im Verlauf.")
            }
            .onAppear {
                breakMinutes = settings.breakMinutes
                targetMinutes = settings.targetMinutes
            }
        }
    }

    private var isValid: Bool {
        combined(time: endTime) > combined(time: startTime)
    }

    private func combined(time: Date) -> Date {
        let calendar = Calendar.current
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: timeComps.hour ?? 0,
            minute: timeComps.minute ?? 0,
            second: 0,
            of: calendar.startOfDay(for: date)
        ) ?? date
    }

    private func save() {
        let dayDate = Calendar.current.startOfDay(for: date)
        guard !days.contains(where: { $0.date == dayDate }) else {
            showsDuplicateAlert = true
            return
        }
        let day = WorkDay(
            date: dayDate,
            startTime: combined(time: startTime),
            endTime: combined(time: endTime),
            breakMinutes: breakMinutes,
            targetMinutes: targetMinutes
        )
        context.insert(day)
        dismiss()
    }
}
