import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkDay.date, order: .reverse) private var days: [WorkDay]

    @State private var plannedStart: Date = .now
    @Namespace private var glassNamespace

    private var today: WorkDay? {
        days.first { Calendar.current.isDateInToday($0.date) }
    }

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
                    GlassEffectContainer(spacing: 24) {
                        VStack(spacing: 24) {
                            if let day = today {
                                if day.isFinished {
                                    FinishedDayCard(
                                        day: day,
                                        totalBalance: totalBalance,
                                        glassNamespace: glassNamespace,
                                        onResume: { resume(day) }
                                    )
                                } else {
                                    RunningDayCard(
                                        day: day,
                                        glassNamespace: glassNamespace,
                                        onFinish: { finish(day) },
                                        onTimesChanged: { reschedule(day) }
                                    )
                                }
                            } else {
                                StartDayCard(
                                    plannedStart: $plannedStart,
                                    settings: settings,
                                    glassNamespace: glassNamespace,
                                    onStart: start
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Heute")
            .onAppear { plannedStart = .now }
        }
    }

    private func start() {
        let day = WorkDay(
            date: .now,
            startTime: plannedStart,
            breakMinutes: settings.breakMinutes,
            targetMinutes: settings.targetMinutes
        )
        withAnimation(.smooth) {
            context.insert(day)
        }
        reschedule(day)
    }

    private func finish(_ day: WorkDay) {
        withAnimation(.smooth) {
            day.endTime = .now
        }
        NotificationManager.shared.cancel(for: day)
    }

    private func resume(_ day: WorkDay) {
        withAnimation(.smooth) {
            day.endTime = nil
        }
        reschedule(day)
    }

    private func reschedule(_ day: WorkDay) {
        guard settings.notificationsEnabled else {
            NotificationManager.shared.cancel(for: day)
            return
        }
        let preAlert = settings.preAlertMinutes
        Task {
            await NotificationManager.shared.scheduleEndOfWork(for: day, preAlertMinutes: preAlert)
        }
    }
}
