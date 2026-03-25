import Testing
@testable import Money_Guard

struct AnalyticsServiceTests {
    @Test("Test: app_open")
    func appOpen_tracksEventInMemory() {
        // Objective: Verify analytics events are captured in memory in order.
        // Given: An in-memory analytics service.
        // When: appOpen and transactionCreated events are tracked.
        // Then: allEvents returns those events in the same sequence.
        let service = InMemoryAnalyticsService()

        service.track(.appOpen)
        service.track(.transactionCreated)

        #expect(service.allEvents() == [.appOpen, .transactionCreated])
    }
}
