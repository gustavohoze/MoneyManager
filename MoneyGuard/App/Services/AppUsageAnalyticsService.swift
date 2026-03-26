import Foundation

struct AppUsageAnalyticsSummary: Equatable {
    let featureCounts: [String: Int]
    let mostUsedFeature: String?
    let averageSessionDurationSeconds: Double
    let sessionCount: Int
}

final class AppUsageAnalyticsService {
    private enum StorageKey {
        static let featureCounts = "analytics.featureCounts"
        static let sessionDurations = "analytics.sessionDurations"
    }

    private let analytics: AnalyticsTracking
    private let defaults: UserDefaults
    private var activeSessionStart: Date?

    init(analytics: AnalyticsTracking, defaults: UserDefaults = .standard) {
        self.analytics = analytics
        self.defaults = defaults
    }

    func appDidLaunch() {
        analytics.track(.appOpen)
    }

    func didSelectFeature(_ tab: MilestoneOneTab) {
        let featureKey = key(for: tab)
        var counts = loadFeatureCounts()
        counts[featureKey, default: 0] += 1
        saveFeatureCounts(counts)

        analytics.track(event(for: tab))
    }

    func sessionDidBecomeActive(at date: Date = Date()) {
        guard activeSessionStart == nil else {
            return
        }

        activeSessionStart = date
        analytics.track(.sessionStarted)
    }

    func sessionDidEnd(at date: Date = Date()) {
        guard let start = activeSessionStart else {
            return
        }

        activeSessionStart = nil
        let duration = max(0, date.timeIntervalSince(start))
        appendSessionDuration(duration)
        analytics.track(
            .sessionEnded,
            properties: [
                "duration_seconds": .double(duration)
            ]
        )
    }

    func summary() -> AppUsageAnalyticsSummary {
        let featureCounts = loadFeatureCounts()
        let durations = loadSessionDurations()
        let average = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)

        return AppUsageAnalyticsSummary(
            featureCounts: featureCounts,
            mostUsedFeature: featureCounts.max(by: { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key > rhs.key
                }
                return lhs.value < rhs.value
            })?.key,
            averageSessionDurationSeconds: average,
            sessionCount: durations.count
        )
    }

    private func key(for tab: MilestoneOneTab) -> String {
        switch tab {
        case .dashboard:
            return "dashboard"
        case .transactions:
            return "transactions"
        case .add:
            return "add"
        case .save:
            return "save"
        case .settings:
            return "settings"
        case .scanner:
            return "scanner"
        }
    }

    private func event(for tab: MilestoneOneTab) -> AnalyticsEvent {
        switch tab {
        case .dashboard:
            return .featureDashboardViewed
        case .transactions:
            return .featureTransactionsViewed
        case .add:
            return .featureAddViewed
        case .save:
            return .featureSaveViewed
        case .settings:
            return .featureSettingsViewed
        case .scanner:
            return .featureScannerViewed
        }
    }

    private func appendSessionDuration(_ duration: TimeInterval) {
        var durations = loadSessionDurations()
        durations.append(duration)

        // Keep a bounded rolling window so analytics storage does not grow forever.
        let maxSamples = 200
        if durations.count > maxSamples {
            durations.removeFirst(durations.count - maxSamples)
        }

        defaults.set(durations, forKey: StorageKey.sessionDurations)
    }

    private func loadFeatureCounts() -> [String: Int] {
        defaults.dictionary(forKey: StorageKey.featureCounts) as? [String: Int] ?? [:]
    }

    private func saveFeatureCounts(_ counts: [String: Int]) {
        defaults.set(counts, forKey: StorageKey.featureCounts)
    }

    private func loadSessionDurations() -> [TimeInterval] {
        defaults.array(forKey: StorageKey.sessionDurations) as? [TimeInterval] ?? []
    }
}
