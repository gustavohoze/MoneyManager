import Foundation
import Testing
import CoreData
@testable import MoneyManager

private struct MockDashboardSettingsProvider: DashboardSettingsProviding {
    let nextSalaryDate: Date?
    let salaryFrequency: String
}

private struct MockDashboardDataProvider: DashboardDataProviding {
    let summary: DashboardSummary

    func loadSummary(asOf date: Date, recentLimit: Int) throws -> DashboardSummary {
        summary
    }
}

@MainActor
struct DashboardViewModelTests {
    @Test("Test: dashboard view model maps summary state")
    func load_withSummary_mapsDashboardState() {
        // Objective: Validate that dashboard state binding is wired correctly from domain summary to UI state.
        let now = Date()
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 450,
                    afterBillsBalance: 420,
                    safeDailySpend: 35,
                    daysUntilIncome: 12,
                    weeklySpending: 500,
                    lastWeekSpending: 430,
                    weeklyBudget: 600,
                    weekDailySpending: [0, 25, 40, 90, 120, 110, 115],
                    topSpendingCategory: "Transport",
                    categoryBreakdown: [
                        DashboardCategoryBreakdown(category: "Transport", total: 300, ratio: 0.6),
                        DashboardCategoryBreakdown(category: "Food", total: 200, ratio: 0.4)
                    ],
                    alerts: [DashboardAlert(title: "Transport spending is up", detail: "30% higher than last week.")],
                    recentTransactions: [
                        DashboardRecentTransaction(
                            id: UUID(),
                            merchant: "Ride",
                            category: "Transport",
                            categoryIcon: "car.fill",
                            account: "Cash",
                            amount: 300,
                            date: now
                        )
                    ]
                )
            )
        )

        viewModel.load(asOf: now)

        #expect(viewModel.currentBalance == 450)
        #expect(viewModel.weeklySpending == 500)
        #expect(viewModel.topSpendingCategory == "Transport")
        #expect(viewModel.lastWeekSpending == 430)
        #expect(viewModel.weekDailySpending.count == 7)
        #expect(viewModel.afterBillsBalance == 420)
        #expect(viewModel.recentTransactions.count == 1)
        #expect(viewModel.recentTransactions.first?.account == "Cash")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Test: dashboard defaults when empty")
    func load_withoutTransactions_returnsDefaults() {
        // Objective: Keep dashboard stable when there is no transaction data.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let viewModel = DashboardViewModel(dataProvider: service)

        viewModel.load()

        #expect(viewModel.currentBalance == 0)
        #expect(viewModel.afterBillsBalance == 0)
        #expect(viewModel.safeDailySpend == 0)
        #expect(viewModel.weeklySpending == 0)
        #expect(viewModel.lastWeekSpending == 0)
        #expect(viewModel.topSpendingCategory == "Uncategorized")
        #expect(viewModel.categoryBreakdown.isEmpty)
        #expect(viewModel.alerts.isEmpty)
        #expect(viewModel.recentTransactions.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Test: dashboard uses injected next salary date")
    func loadSummary_withInjectedMonthlySettings_usesConfiguredIncomeDate() throws {
        // Objective: Verify dashboard calculations are wired to settings provider, not hardcoded defaults.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let configuredPayDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20)) ?? now

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                nextSalaryDate: configuredPayDate,
                salaryFrequency: "Monthly"
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysUntilIncome == 3)
    }

    @Test("Test: dashboard advances weekly salary schedule")
    func loadSummary_withPastWeeklySalary_rollsForwardToNextWeek() throws {
        // Objective: Ensure weekly schedules are advanced correctly when configured date is in the past.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let lastPayDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)) ?? now

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                nextSalaryDate: lastPayDate,
                salaryFrequency: "Weekly"
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysUntilIncome == 1)
    }

    @Test("Test: dashboard advances biweekly salary schedule")
    func loadSummary_withPastBiweeklySalary_rollsForwardTwoWeeks() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let lastPayDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)) ?? now

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                nextSalaryDate: lastPayDate,
                salaryFrequency: "Biweekly"
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysUntilIncome == 7)
    }

    @Test("Test: dashboard monthly schedule clamps invalid day for short month")
    func loadSummary_withMonthly31st_clampsToMonthEnd() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)) ?? Date()
        let monthlyReference = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31)) ?? now

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                nextSalaryDate: monthlyReference,
                salaryFrequency: "Monthly"
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysUntilIncome == 8)
    }

    @Test("Test: category prompt appears for uncategorized-only data")
    func shouldShowCategoryPrompt_whenOnlyUncategorized_returnsTrue() {
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 0,
                    afterBillsBalance: 0,
                    safeDailySpend: 0,
                    daysUntilIncome: 1,
                    weeklySpending: 100,
                    lastWeekSpending: 100,
                    weeklyBudget: 200,
                    weekDailySpending: Array(repeating: 0, count: 7),
                    topSpendingCategory: DashboardDomainConstants.uncategorized,
                    categoryBreakdown: [
                        DashboardCategoryBreakdown(
                            category: DashboardDomainConstants.uncategorized,
                            total: 100,
                            ratio: 1
                        )
                    ],
                    alerts: [],
                    recentTransactions: []
                )
            )
        )

        viewModel.load()
        #expect(viewModel.shouldShowCategoryPrompt)
    }

    @Test("Test: derived alerts include budget warning at threshold")
    func derivedAlerts_whenWeeklyProgressAboveEightyPercent_includesBudgetWarning() {
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 0,
                    afterBillsBalance: 0,
                    safeDailySpend: 0,
                    daysUntilIncome: 1,
                    weeklySpending: 85,
                    lastWeekSpending: 80,
                    weeklyBudget: 100,
                    weekDailySpending: Array(repeating: 0, count: 7),
                    topSpendingCategory: "Food",
                    categoryBreakdown: [DashboardCategoryBreakdown(category: "Food", total: 85, ratio: 1)],
                    alerts: [],
                    recentTransactions: []
                )
            )
        )

        viewModel.load()
        #expect(viewModel.derivedAlerts.first?.title.contains("Budget warning") == true)
    }
}
