import Foundation
import Testing
import UserNotifications
@testable import MoneyManager

private final class NotificationCenterSchedulingMock: NotificationCenterScheduling {
    var status: UNAuthorizationStatus = .authorized
    var requestAuthorizationResult = true
    private(set) var addedRequestIDs: [String] = []
    private(set) var removedRequestIDs: [String] = []

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization() async -> Bool {
        requestAuthorizationResult
    }

    func add(_ request: UNNotificationRequest) async {
        addedRequestIDs.append(request.identifier)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedRequestIDs.append(contentsOf: identifiers)
    }
}

struct NotificationSchedulingServiceTests {
    @Test("Test: scheduler adds enabled notifications and removes disabled ones")
    func syncPreferences_whenAuthorized_appliesAddAndRemoveActions() async {
        let center = NotificationCenterSchedulingMock()
        center.status = .authorized
        let scheduler = LocalNotificationScheduler(center: center)

        await scheduler.syncPreferences(
            dailyReminder: true,
            monthlyReview: false
        )

        #expect(center.addedRequestIDs.contains(LocalNotificationScheduler.IDs.dailyReminder))
        #expect(center.removedRequestIDs.contains(LocalNotificationScheduler.IDs.monthlyReview))
        #expect(center.removedRequestIDs.contains(LocalNotificationScheduler.LegacyIDs.budgetExceeded))
        #expect(center.removedRequestIDs.contains(LocalNotificationScheduler.LegacyIDs.weeklySummary))
        #expect(center.removedRequestIDs.contains(LocalNotificationScheduler.LegacyIDs.unusualSpending))
    }

    @Test("Test: scheduler skips scheduling when permission is denied")
    func syncPreferences_whenPermissionDenied_doesNotSchedule() async {
        let center = NotificationCenterSchedulingMock()
        center.status = .notDetermined
        center.requestAuthorizationResult = false
        let scheduler = LocalNotificationScheduler(center: center)

        await scheduler.syncPreferences(
            dailyReminder: true,
            monthlyReview: true
        )

        #expect(center.addedRequestIDs.isEmpty)
        #expect(center.removedRequestIDs.isEmpty)
    }
}
