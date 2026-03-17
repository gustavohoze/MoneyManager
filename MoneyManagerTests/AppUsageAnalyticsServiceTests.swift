import Foundation
import Testing
@testable import MoneyManager

struct AppUsageAnalyticsServiceTests {
    @Test("Test: tracks most used feature")
    func summary_returnsMostUsedFeatureByCount() {
        let suiteName = "AppUsageAnalyticsServiceTests.feature.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Expected to create isolated defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let analytics = InMemoryAnalyticsService()
        let service = AppUsageAnalyticsService(analytics: analytics, defaults: defaults)

        service.didSelectFeature(.dashboard)
        service.didSelectFeature(.transactions)
        service.didSelectFeature(.dashboard)

        let summary = service.summary()
        #expect(summary.mostUsedFeature == "dashboard")
        #expect(summary.featureCounts["dashboard"] == 2)
        #expect(summary.featureCounts["transactions"] == 1)
    }

    @Test("Test: computes average session duration")
    func summary_computesAverageSessionDuration() {
        let suiteName = "AppUsageAnalyticsServiceTests.session.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Expected to create isolated defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)

        let analytics = InMemoryAnalyticsService()
        let service = AppUsageAnalyticsService(analytics: analytics, defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)

        service.sessionDidBecomeActive(at: start)
        service.sessionDidEnd(at: start.addingTimeInterval(40))
        service.sessionDidBecomeActive(at: start.addingTimeInterval(100))
        service.sessionDidEnd(at: start.addingTimeInterval(160))

        let summary = service.summary()
        #expect(summary.sessionCount == 2)
        #expect(summary.averageSessionDurationSeconds == 50)

        let events = analytics.allEvents()
        #expect(events.contains(.sessionStarted))
        #expect(events.contains(.sessionEnded))
    }
}
