import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(sort: \WorkDay.date, order: .reverse) private var days: [WorkDay]

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
                                        onFinish: { finish(day, at: $0) },
                                        onTimesChanged: { reschedule(day) }
                                    )
                                }
                            } else {
                                StartDayCard(
                                    settings: settings,
                                    glassNamespace: glassNamespace,
                                    onStart: { start(at: $0) }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Heute")
        }
    }

    private func start(at startTime: Date) {
        let day = WorkDay(
            date: .now,
            startTime: startTime,
            breakMinutes: settings.breakMinutes,
            targetMinutes: settings.targetMinutes
        )
        withAnimation(.smooth) {
            context.insert(day)
        }
        reschedule(day)
    }

    private func finish(_ day: WorkDay, at endTime: Date) {
        withAnimation(.smooth) {
            day.endTime = endTime
        }
        NotificationManager.shared.cancel(for: day)
        Task { await LiveActivityManager.shared.endAll() }
    }

    private func resume(_ day: WorkDay) {
        withAnimation(.smooth) {
            day.endTime = nil
        }
        reschedule(day)
    }

    private func reschedule(_ day: WorkDay) {
        let liveActivityEnabled = settings.liveActivityEnabled
        Task { await LiveActivityManager.shared.sync(day: day, enabled: liveActivityEnabled) }

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
