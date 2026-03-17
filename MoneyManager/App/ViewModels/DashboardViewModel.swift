import Foundation
import Combine

struct DashboardViewState: Equatable {
    var currentBalance: Double = 0
    var afterBillsBalance: Double = 0
    var safeDailySpend: Double = 0
    var daysRemainingInCycle: Int = 0
    var weeklySpending: Double = 0
    var lastWeekSpending: Double = 0
    var weeklyBudget: Double = 0
    var weekDailySpending: [Double] = Array(repeating: 0, count: 7)
    var topSpendingCategory: String = DashboardDomainConstants.uncategorized
    var categoryBreakdown: [DashboardCategoryBreakdown] = []
    var alerts: [DashboardAlert] = []
    var isWeeklyBudgetUserConfigured: Bool = true
    var budgetWarningThreshold: Int = 80
    var budgetCriticalThreshold: Int = 100
    var recentTransactions: [DashboardRecentTransaction] = []
    var errorMessage: String?
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var state: DashboardViewState = DashboardViewState()

    private let dataProvider: DashboardDataProviding
    private var cancellables: Set<AnyCancellable> = []

    init(
        dataProvider: DashboardDataProviding,
        refreshTrigger: DashboardRefreshTriggering? = nil
    ) {
        self.dataProvider = dataProvider

        refreshTrigger?.updates
            .sink { [weak self] in
                self?.load()
            }
            .store(in: &cancellables)
    }

    func load(asOf date: Date = Date()) {
        do {
            let summary = try dataProvider.loadSummary(asOf: date, recentLimit: 3)
            state = DashboardViewState(
                currentBalance: summary.currentBalance,
                afterBillsBalance: summary.afterBillsBalance,
                safeDailySpend: summary.safeDailySpend,
                daysRemainingInCycle: summary.daysRemainingInCycle,
                weeklySpending: summary.weeklySpending,
                lastWeekSpending: summary.lastWeekSpending,
                weeklyBudget: summary.weeklyBudget,
                weekDailySpending: summary.weekDailySpending,
                topSpendingCategory: summary.topSpendingCategory,
                categoryBreakdown: summary.categoryBreakdown,
                alerts: summary.alerts,
                isWeeklyBudgetUserConfigured: summary.isWeeklyBudgetUserConfigured,
                budgetWarningThreshold: summary.budgetWarningThreshold,
                budgetCriticalThreshold: summary.budgetCriticalThreshold,
                recentTransactions: summary.recentTransactions,
                errorMessage: nil
            )
        } catch {
            state = DashboardViewState(errorMessage: error.localizedDescription)
        }
    }

    func defaultWeeklyDayIndex() -> Int {
        // Default to today (or appropriate day in week)
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        return max(0, weekday - 2) // Adjust for 0-based indexing
    }
}

extension DashboardViewModel {
    var currentBalance: Double { state.currentBalance }
    var afterBillsBalance: Double { state.afterBillsBalance }
    var safeDailySpend: Double { state.safeDailySpend }
    var daysRemainingInCycle: Int { state.daysRemainingInCycle }
    var weeklySpending: Double { state.weeklySpending }
    var lastWeekSpending: Double { state.lastWeekSpending }
    var weeklyBudget: Double { state.weeklyBudget }
    var weekDailySpending: [Double] { state.weekDailySpending }
    var topSpendingCategory: String { state.topSpendingCategory }
    var categoryBreakdown: [DashboardCategoryBreakdown] { state.categoryBreakdown }
    var alerts: [DashboardAlert] { state.alerts }
    var isWeeklyBudgetUserConfigured: Bool { state.isWeeklyBudgetUserConfigured }
    var budgetWarningThreshold: Int { state.budgetWarningThreshold }
    var budgetCriticalThreshold: Int { state.budgetCriticalThreshold }
    var recentTransactions: [DashboardRecentTransaction] { state.recentTransactions }
    var errorMessage: String? { state.errorMessage }
}
