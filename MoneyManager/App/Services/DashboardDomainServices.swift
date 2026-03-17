import Foundation

enum DashboardDomainConstants {
    static let uncategorized = "Uncategorized"
    static let unknown = "Unknown"
    static let billsCategory = "Bills"
    static let defaultCategoryIcon = "questionmark.circle"
    static let expenseType = "expense"
    static let incomeType = "income"
}

struct DashboardDateWindows {
    let asOf: Date
    let startOfToday: Date
    let startOfWindow: Date
    let startOfLastWeek: Date
    let endOfLastWeek: Date
    let startOfMonthWindow: Date

    init(referenceDate: Date, calendar: Calendar) {
        asOf = referenceDate
        startOfToday = calendar.startOfDay(for: referenceDate)
        startOfWindow = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        startOfLastWeek = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        endOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday
        startOfMonthWindow = calendar.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday
    }
}

struct DashboardTrendSnapshot {
    let weeklySpending: Double
    let lastWeekSpending: Double
    let weekDailySpending: [Double]
    let currentWeekByCategory: [String: Double]
    let lastWeekByCategory: [String: Double]
}

struct DashboardTrendCalculator {
    func makeTrend(
        expenses: [(amount: Double, date: Date, category: String)],
        windows: DashboardDateWindows,
        calendar: Calendar
    ) -> DashboardTrendSnapshot {
        var weeklySpending = 0.0
        var lastWeekSpending = 0.0
        var weekDailySpending = Array(repeating: 0.0, count: 7)
        var currentWeekByCategory = [String: Double]()
        var lastWeekByCategory = [String: Double]()

        for expense in expenses {
            if expense.date >= windows.startOfWindow && expense.date <= windows.asOf {
                weeklySpending += expense.amount
                let dayOffset = calendar.dateComponents([.day], from: windows.startOfWindow, to: expense.date).day ?? 0
                if (0..<7).contains(dayOffset) {
                    weekDailySpending[dayOffset] += expense.amount
                }
                currentWeekByCategory[expense.category, default: 0] += expense.amount
            } else if expense.date >= windows.startOfLastWeek && expense.date <= windows.endOfLastWeek {
                lastWeekSpending += expense.amount
                lastWeekByCategory[expense.category, default: 0] += expense.amount
            }
        }

        return DashboardTrendSnapshot(
            weeklySpending: weeklySpending,
            lastWeekSpending: lastWeekSpending,
            weekDailySpending: weekDailySpending,
            currentWeekByCategory: currentWeekByCategory,
            lastWeekByCategory: lastWeekByCategory
        )
    }
}

struct DashboardCategoryInsights {
    let topCategory: String
    let categoryBreakdown: [DashboardCategoryBreakdown]
}

struct DashboardCategoryInsightCalculator {
    func makeInsights(expenseByCategory: [String: Double], expenseTotal: Double) -> DashboardCategoryInsights {
        let topCategory = expenseByCategory.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        })?.key ?? DashboardDomainConstants.uncategorized

        let categoryBreakdown = expenseByCategory
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { pair in
                DashboardCategoryBreakdown(
                    category: pair.key,
                    total: pair.value,
                    ratio: expenseTotal > 0 ? (pair.value / expenseTotal) : 0
                )
            }

        return DashboardCategoryInsights(topCategory: topCategory, categoryBreakdown: categoryBreakdown)
    }
}

struct DashboardProjection {
    let currentBalance: Double
    let afterBillsBalance: Double
    let safeDailySpend: Double
    let daysUntilIncome: Int
    let weeklyBudget: Double
}

struct DashboardProjectionCalculator {
    func makeProjection(
        incomeTotal: Double,
        expenseTotal: Double,
        billsLast30Days: Double,
        daysUntilIncome: Int,
        weeklySpending: Double,
        lastWeekSpending: Double
    ) -> DashboardProjection {
        let currentBalance = incomeTotal - expenseTotal
        let upcomingBills = billsLast30Days / 30 * Double(daysUntilIncome)
        let afterBillsBalance = currentBalance - upcomingBills
        let safeDailySpend = max(afterBillsBalance, 0) / Double(max(1, daysUntilIncome))
        let weeklyBudget = max(weeklySpending, lastWeekSpending, 1) * 1.2

        return DashboardProjection(
            currentBalance: currentBalance,
            afterBillsBalance: afterBillsBalance,
            safeDailySpend: safeDailySpend,
            daysUntilIncome: daysUntilIncome,
            weeklyBudget: weeklyBudget
        )
    }
}

struct DashboardAlertFactory {
    func makeAlerts(
        safeDailySpend: Double,
        weekDailySpending: [Double],
        currentWeekByCategory: [String: Double],
        lastWeekByCategory: [String: Double],
        currencyText: (Double) -> String
    ) -> [DashboardAlert] {
        var alerts: [DashboardAlert] = []

        if safeDailySpend > 0 {
            let todaySpend = weekDailySpending.last ?? 0
            if todaySpend > safeDailySpend {
                alerts.append(
                    DashboardAlert(
                        title: "Daily spending above safe limit",
                        detail: "Spent \(currencyText(todaySpend)) today vs safe \(currencyText(safeDailySpend))."
                    )
                )
            }
        }

        for (category, currentTotal) in currentWeekByCategory {
            let previousTotal = lastWeekByCategory[category, default: 0]
            guard previousTotal > 0 else { continue }
            let change = (currentTotal - previousTotal) / previousTotal
            if change > 0.30 {
                alerts.append(
                    DashboardAlert(
                        title: "\(category) spending is up",
                        detail: "\(Int(change * 100))% higher than last week."
                    )
                )
            }
        }

        return Array(alerts.prefix(2))
    }
}
