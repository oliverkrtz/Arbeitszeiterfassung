import SwiftUI
import SwiftData
import UserNotifications

@main
struct ArbeitszeiterfassungApp: App {
    @State private var settings = AppSettings()
    private static let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(settings)
        }
        .modelContainer(for: WorkDay.self)
    }
}

/// Zeigt Benachrichtigungen auch an, während die App im Vordergrund ist.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
