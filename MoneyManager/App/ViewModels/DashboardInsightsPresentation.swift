import Foundation
import SwiftUI

extension DashboardViewModel {
    var weeklyProgress: Double {
        guard weeklyBudget > 0 else { return 0 }
        return min(max(weeklySpending / weeklyBudget, 0), 1)
    }

    var categoryRows: [DashboardCategoryBreakdown] {
        categoryBreakdown.filter { $0.total > 0 }
    }

    var shouldShowCategoryPrompt: Bool {
        guard !categoryRows.isEmpty else { return true }
        return categoryRows.count == 1 && categoryRows[0].category.caseInsensitiveCompare("Uncategorized") == .orderedSame
    }

    var derivedAlerts: [DashboardAlert] {
        var merged = alerts

        if weeklyProgress >= 1 {
            merged.insert(
                DashboardAlert(
                    title: "⚠︎ " + String(localized: "Budget exceeded"),
                    detail: String(localized: "Weekly spending is above budget.")
                ),
                at: 0
            )
        } else if weeklyProgress >= 0.8 {
            merged.insert(
                DashboardAlert(
                    title: "⚠︎ " + String(localized: "Budget warning"),
                    detail: String(localized: "You have used over 80% of this week budget.")
                ),
                at: 0
            )
        }

        return Array(merged.prefix(3))
    }

    var weeklyDeltaMessage: String {
        guard lastWeekSpending > 0 else {
            return String(localized: "Track another week to unlock comparison insights.")
        }

        let delta = weeklySpending - lastWeekSpending
        let percent = abs(delta / lastWeekSpending) * 100
        if delta > 0 {
            return "\(String(localized: "Your spending is")) \(Int(percent))% \(String(localized: "higher than last week."))"
        }
        if delta < 0 {
            return "\(String(localized: "Your spending is")) \(Int(percent))% \(String(localized: "lower than last week."))"
        }
        return String(localized: "Your spending is similar to last week.")
    }

    var spendingPaceMessage: String {
        if weeklyProgress >= 1 {
            return String(localized: "You are overspending this week.")
        }
        if weeklyProgress >= 0.8 {
            return String(localized: "You are spending faster than usual.")
        }
        return String(localized: "You are on track this week.")
    }

    var weeklyComparisonSummary: String {
        guard lastWeekSpending > 0 else {
            return String(localized: "Track another week to unlock comparison insights.")
        }

        let delta = weeklySpending - lastWeekSpending
        let percent = Int(abs(delta / lastWeekSpending) * 100)

        if delta > 0 {
            return "+\(percent)% " + String(localized: "vs last week")
        }
        if delta < 0 {
            return "-\(percent)% " + String(localized: "vs last week")
        }
        return String(localized: "Similar to last week")
    }

    var weeklyComparisonColor: Color {
        guard lastWeekSpending > 0 else {
            return .secondary
        }

        let delta = weeklySpending - lastWeekSpending

        if delta > 0 {
            return .red
        }
        if delta < 0 {
            return .green
        }
        return .secondary
    }

    var spendingPaceColor: Color {
        if weeklyProgress >= 1 {
            return .red
        }
        if weeklyProgress >= 0.8 {
            return .orange
        }
        return .green
    }

    func uncategorizedCountEstimate(recentCount: Int) -> Int {
        let uncategorizedRatio = categoryRows.first(where: { $0.category.caseInsensitiveCompare("Uncategorized") == .orderedSame })?.ratio ?? 0
        if uncategorizedRatio >= 0.99 {
            return max(3, recentCount)
        }
        return max(1, Int((Double(max(recentCount, 3)) * uncategorizedRatio).rounded(.up)))
    }

    func categoryBarRatio(for item: DashboardCategoryBreakdown) -> CGFloat {
        guard let maxTotal = categoryRows.map(\.total).max(), maxTotal > 0 else {
            return 0
        }
        return CGFloat(item.total / maxTotal)
    }

    func alertTone(for alert: DashboardAlert) -> (title: Color, detail: Color, background: Color) {
        let title = alert.title.lowercased()
        let detail = alert.detail.lowercased()

        if title.contains("exceeded") || title.contains("above") || detail.contains("above") {
            return (title: .red, detail: .red.opacity(0.9), background: Color.red.opacity(0.12))
        }
        if title.contains("warning") || title.contains("up") || detail.contains("higher") {
            return (title: .orange, detail: .orange.opacity(0.95), background: Color.orange.opacity(0.14))
        }
        return (title: .green, detail: .green.opacity(0.95), background: Color.green.opacity(0.14))
    }
}
