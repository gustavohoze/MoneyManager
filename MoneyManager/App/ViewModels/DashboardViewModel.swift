import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var currentBalance: Double = 0
    @Published private(set) var afterBillsBalance: Double = 0
    @Published private(set) var safeDailySpend: Double = 0
    @Published private(set) var daysUntilIncome: Int = 0
    @Published private(set) var weeklySpending: Double = 0
    @Published private(set) var lastWeekSpending: Double = 0
    @Published private(set) var weeklyBudget: Double = 0
    @Published private(set) var weekDailySpending: [Double] = Array(repeating: 0, count: 7)
    @Published private(set) var topSpendingCategory: String = "Uncategorized"
    @Published private(set) var categoryBreakdown: [DashboardCategoryBreakdown] = []
    @Published private(set) var alerts: [DashboardAlert] = []
    @Published private(set) var recentTransactions: [DashboardRecentTransaction] = []
    @Published private(set) var errorMessage: String?

    private let dataProvider: DashboardDataProviding

    init(dataProvider: DashboardDataProviding) {
        self.dataProvider = dataProvider
    }

    func load(asOf date: Date = Date()) {
        do {
            let summary = try dataProvider.loadSummary(asOf: date, recentLimit: 3)
            currentBalance = summary.currentBalance
            afterBillsBalance = summary.afterBillsBalance
            safeDailySpend = summary.safeDailySpend
            daysUntilIncome = summary.daysUntilIncome
            weeklySpending = summary.weeklySpending
            lastWeekSpending = summary.lastWeekSpending
            weeklyBudget = summary.weeklyBudget
            weekDailySpending = summary.weekDailySpending
            topSpendingCategory = summary.topSpendingCategory
            categoryBreakdown = summary.categoryBreakdown
            alerts = summary.alerts
            recentTransactions = summary.recentTransactions
            errorMessage = nil
        } catch {
            currentBalance = 0
            afterBillsBalance = 0
            safeDailySpend = 0
            daysUntilIncome = 0
            weeklySpending = 0
            lastWeekSpending = 0
            weeklyBudget = 0
            weekDailySpending = Array(repeating: 0, count: 7)
            topSpendingCategory = "Uncategorized"
            categoryBreakdown = []
            alerts = []
            recentTransactions = []
            errorMessage = error.localizedDescription
        }
    }
}
