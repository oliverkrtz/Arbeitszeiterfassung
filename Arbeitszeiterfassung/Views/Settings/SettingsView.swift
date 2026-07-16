import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Query private var days: [WorkDay]

    @State private var notificationsDenied = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Picker("Stunden", selection: targetHoursBinding) {
                        ForEach(0...12, id: \.self) { Text("\($0) Std").tag($0) }
                    }
                    Picker("Minuten", selection: targetRestMinutesBinding) {
                        ForEach(0..<60, id: \.self) { Text("\($0) Min").tag($0) }
                    }
                    Stepper(value: $settings.breakMinutes, in: 0...120, step: 5) {
                        LabeledContent("Pause", value: "\(settings.breakMinutes) Min")
                    }
                } header: {
                    Text("Sollarbeitszeit pro Tag")
                } footer: {
                    Text("Feierabend = Start + Sollarbeitszeit + Pause. Gesetzlich vorgeschrieben: mind. 30 Min Pause ab 6 h, 45 Min ab 9 h Arbeitszeit.")
                }

                Section {
                    Toggle("Feierabend-Benachrichtigung", isOn: $settings.notificationsEnabled)
                    if settings.notificationsEnabled {
                        Picker("Vorwarnung", selection: $settings.preAlertMinutes) {
                            Text("Aus").tag(0)
                            ForEach([5, 10, 15, 30], id: \.self) {
                                Text("\($0) Min vorher").tag($0)
                            }
                        }
                    }
                    if notificationsDenied {
                        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                            Label("Mitteilungen in den Systemeinstellungen erlauben", systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Benachrichtigung")
                } footer: {
                    Text("Die Benachrichtigung wird beim Eintragen der Startzeit lokal auf dem iPhone geplant — es wird kein Server benötigt.")
                }

                Section {
                    Stepper(value: $settings.startBalanceMinutes, in: -600 * 60...600 * 60, step: 5) {
                        LabeledContent("Startsaldo") {
                            BalanceText(minutes: settings.startBalanceMinutes)
                        }
                    }
                } header: {
                    Text("Gleitzeitkonto")
                } footer: {
                    Text("Übernimm hier deinen aktuellen Gleitzeitstand, falls dein Konto nicht bei ±0 beginnt. Gedrückt halten zum schnellen Ändern.")
                }
            }
            .navigationTitle("Einstellungen")
            .onChange(of: settings.notificationsEnabled) { _, enabled in
                handleNotificationToggle(enabled)
            }
            .task {
                await refreshAuthorizationStatus()
            }
        }
    }

    // MARK: - Sollzeit-Bindings (Stunden/Minuten getrennt)

    private var targetHoursBinding: Binding<Int> {
        Binding(
            get: { settings.targetMinutes / 60 },
            set: { settings.targetMinutes = $0 * 60 + settings.targetMinutes % 60 }
        )
    }

    private var targetRestMinutesBinding: Binding<Int> {
        Binding(
            get: { settings.targetMinutes % 60 },
            set: { settings.targetMinutes = (settings.targetMinutes / 60) * 60 + $0 }
        )
    }

    // MARK: - Benachrichtigungen

    private func handleNotificationToggle(_ enabled: Bool) {
        let today = days.first {
            Calendar.current.isDateInToday($0.date) && !$0.isFinished
        }
        if enabled {
            let preAlert = settings.preAlertMinutes
            Task {
                if let today {
                    await NotificationManager.shared.scheduleEndOfWork(for: today, preAlertMinutes: preAlert)
                } else {
                    await NotificationManager.shared.requestAuthorization()
                }
                await refreshAuthorizationStatus()
            }
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }

    private func refreshAuthorizationStatus() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationsDenied = settings.notificationsEnabled && status == .denied
    }
}
