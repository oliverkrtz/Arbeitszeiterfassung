import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkDay.date, order: .reverse) private var days: [WorkDay]

    @State private var editingDay: WorkDay?
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(days) { day in
                    Button {
                        editingDay = day
                    } label: {
                        WorkDayRow(day: day)
                    }
                    .foregroundStyle(.primary)
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if days.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Einträge",
                        systemImage: "calendar.badge.clock",
                        description: Text("Starte deinen ersten Arbeitstag im Tab „Heute“ oder trage einen Tag nach.")
                    )
                }
            }
            .navigationTitle("Verlauf")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Tag nachtragen", systemImage: "plus") {
                        showingAddSheet = true
                    }
                }
            }
            .sheet(item: $editingDay) { day in
                WorkDayEditorSheet(day: day)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWorkDaySheet()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let day = days[index]
            NotificationManager.shared.cancel(for: day)
            context.delete(day)
        }
    }
}

struct WorkDayRow: View {
    let day: WorkDay

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.date.formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))
                    .font(.body.weight(.medium))
                Text(timeRange)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            if let balance = day.balanceMinutes {
                BalanceText(minutes: balance)
                    .font(.callout.weight(.medium))
            } else {
                Text("läuft")
                    .font(.footnote)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 2)
    }

    private var timeRange: String {
        let start = day.startTime.formatted(date: .omitted, time: .shortened)
        if let end = day.endTime {
            return "\(start) – \(end.formatted(date: .omitted, time: .shortened)) · \(day.breakMinutes) Min Pause"
        }
        return "seit \(start)"
    }
}
