import Foundation

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
