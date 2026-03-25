import Foundation
import UserNotifications

protocol NotificationCenterScheduling {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async -> Bool
    func add(_ request: UNNotificationRequest) async
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

struct UserNotificationCenterAdapter: NotificationCenterScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func add(_ request: UNNotificationRequest) async {
        try? await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

protocol NotificationScheduling {
    func syncPreferences(
        dailyReminder: Bool,
        monthlyReview: Bool
    ) async
}

struct LocalNotificationScheduler: NotificationScheduling {
    #if DEBUG
    enum DebugNotificationKind: String, CaseIterable, Identifiable {
        case dailyReminder
        case monthlyReview

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dailyReminder:
                return String(localized: "Log today's expenses")
            case .monthlyReview:
                return String(localized: "Monthly spending check")
            }
        }

        var body: String {
            switch self {
            case .dailyReminder:
                return String(localized: "Debug test: daily reminder notification.")
            case .monthlyReview:
                return String(localized: "Debug test: monthly review notification.")
            }
        }
    }
    #endif

    enum IDs {
        static let dailyReminder = "settings.notifications.dailyReminder"
        static let monthlyReview = "settings.notifications.monthlyReview"
    }

    enum LegacyIDs {
        static let dailyWarning = "settings.notifications.dailyWarning"
        static let budgetExceeded = "settings.notifications.budgetExceeded"
        static let weeklySummary = "settings.notifications.weeklySummary"
        static let unusualSpending = "settings.notifications.unusualSpending"
    }

    private let center: NotificationCenterScheduling

    init(center: NotificationCenterScheduling = UserNotificationCenterAdapter()) {
        self.center = center
    }

    func syncPreferences(
        dailyReminder: Bool,
        monthlyReview: Bool
    ) async {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else {
            return
        }

        center.removePendingNotificationRequests(withIdentifiers: [
            LegacyIDs.dailyWarning,
            LegacyIDs.budgetExceeded,
            LegacyIDs.weeklySummary,
            LegacyIDs.unusualSpending
        ])

        if dailyReminder {
            await scheduleDailyReminder()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.dailyReminder])
        }

        if monthlyReview {
            await scheduleMonthlyReview()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.monthlyReview])
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        switch await center.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return await center.requestAuthorization()
        @unknown default:
            return false
        }
    }

    private func scheduleDailyReminder() async {
        var date = DateComponents()
        date.hour = 20
        date.minute = 0

        let dailyTitles = [
            String(localized: "Log today's expenses"),
            String(localized: "Did you track your spending today?"),
            String(localized: "Keep your budget on track!"),
            String(localized: "Stay mindful of your money"),
            String(localized: "Quick check-in: expenses")
        ]
        let dailyBodies = [
            String(localized: "Take one minute to record today's spending so your totals stay accurate."),
            String(localized: "A little tracking goes a long way. Add your expenses now!"),
            String(localized: "Don't forget to log your purchases for a clearer picture."),
            String(localized: "Your future self will thank you for tracking today."),
            String(localized: "Consistency is key. Add your expenses!")
        ]
        let content = UNMutableNotificationContent()
        content.title = dailyTitles.randomElement() ?? dailyTitles[0]
        content.body = dailyBodies.randomElement() ?? dailyBodies[0]
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.dailyReminder, content: content, trigger: trigger)
        await center.add(request)
    }

    private func scheduleMonthlyReview() async {
        var date = DateComponents()
        date.day = 1
        date.hour = 20
        date.minute = 30

        let monthlyTitles = [
            String(localized: "Monthly spending check"),
            String(localized: "How did your month go?"),
            String(localized: "Review your budget"),
            String(localized: "Time for a monthly recap!"),
            String(localized: "Reflect & plan ahead")
        ]
        let monthlyBodies = [
            String(localized: "Review your month-to-date spending and adjust your next month budget."),
            String(localized: "Take a moment to see how your spending matched your goals."),
            String(localized: "Check your categories and set a plan for next month."),
            String(localized: "A quick review now helps you stay on track all year."),
            String(localized: "Celebrate your wins and plan for improvements!")
        ]
        let content = UNMutableNotificationContent()
        content.title = monthlyTitles.randomElement() ?? monthlyTitles[0]
        content.body = monthlyBodies.randomElement() ?? monthlyBodies[0]
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.monthlyReview, content: content, trigger: trigger)
        await center.add(request)
    }

    #if DEBUG
    func scheduleDebugNotification(kind: DebugNotificationKind) async {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = kind.title
        content.body = kind.body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "settings.notifications.debug.\(kind.rawValue)",
            content: content,
            trigger: trigger
        )
        await center.add(request)
    }
    #endif
}
