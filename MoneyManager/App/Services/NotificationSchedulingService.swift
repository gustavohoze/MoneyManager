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
        dailyWarning: Bool,
        budgetExceeded: Bool,
        weeklySummary: Bool,
        unusualSpending: Bool
    ) async
}

struct LocalNotificationScheduler: NotificationScheduling {
    enum IDs {
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
        dailyWarning: Bool,
        budgetExceeded: Bool,
        weeklySummary: Bool,
        unusualSpending: Bool
    ) async {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else {
            return
        }

        if dailyWarning {
            await scheduleDailyWarning()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.dailyWarning])
        }

        if budgetExceeded {
            await scheduleBudgetExceededReminder()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.budgetExceeded])
        }

        if weeklySummary {
            await scheduleWeeklySummary()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.weeklySummary])
        }

        if unusualSpending {
            await scheduleUnusualSpendingReminder()
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [IDs.unusualSpending])
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

    private func scheduleDailyWarning() async {
        var date = DateComponents()
        date.hour = 20
        date.minute = 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Daily spending check")
        content.body = String(localized: "Review today spending against your safe daily limit.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.dailyWarning, content: content, trigger: trigger)
        await center.add(request)
    }

    private func scheduleBudgetExceededReminder() async {
        var date = DateComponents()
        date.hour = 21
        date.minute = 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Budget reminder")
        content.body = String(localized: "Check your category budgets to avoid overspending this month.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.budgetExceeded, content: content, trigger: trigger)
        await center.add(request)
    }

    private func scheduleWeeklySummary() async {
        var date = DateComponents()
        date.weekday = 1
        date.hour = 19
        date.minute = 0

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Weekly spending summary")
        content.body = String(localized: "Open MoneyManager to review your weekly spending trends.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.weeklySummary, content: content, trigger: trigger)
        await center.add(request)
    }

    private func scheduleUnusualSpendingReminder() async {
        var date = DateComponents()
        date.hour = 21
        date.minute = 30

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Spending anomaly check")
        content.body = String(localized: "Review recent transactions for unusual spending patterns.")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: IDs.unusualSpending, content: content, trigger: trigger)
        await center.add(request)
    }
}
