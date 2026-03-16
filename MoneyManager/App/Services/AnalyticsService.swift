import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case appOpen = "app_open"
    case transactionCreated = "transaction_created"
    case transactionDeleted = "transaction_deleted"
    case categoryChanged = "category_changed"
    case merchantCorrected = "merchant_corrected"
}

protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
    func allEvents() -> [AnalyticsEvent]
}

final class InMemoryAnalyticsService: AnalyticsTracking {
    private var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }

    func allEvents() -> [AnalyticsEvent] {
        events
    }
}
