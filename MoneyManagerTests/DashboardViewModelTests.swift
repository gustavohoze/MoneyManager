import Foundation
import Testing
import CoreData
@testable import Money_Guard

private struct MockDashboardSettingsProvider: DashboardSettingsProviding {
    let budgetWarningThreshold: Int
    let budgetCriticalThreshold: Int
    let defaultMonthlyBudget: Double
    let openingBalance: Double
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
                    daysRemainingInCycle: 12,
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

    @Test("Test: dashboard uses configured cycle settings")
    func loadSummary_withInjectedMonthlySettings_usesConfiguredCycleDays() throws {
        // Objective: Verify dashboard cycle calculations are wired to settings provider, not hardcoded defaults.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysRemainingInCycle == 15)
    }

    @Test("Test: dashboard keeps consistent cycle days")
    func loadSummary_withPastWeeklySettings_keepsCycleWindowStable() throws {
        // Objective: Keep remaining cycle-day calculations stable under custom settings.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysRemainingInCycle == 15)
    }

    @Test("Test: dashboard supports non-default thresholds")
    func loadSummary_withCustomThresholdSettings_returnsSummary() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 17)) ?? Date()
        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysRemainingInCycle == 15)
    }

    @Test("Test: dashboard cycle days clamp in short month")
    func loadSummary_withFebruaryDate_returnsExpectedCycleDays() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let calendar = Calendar(identifier: .iso8601)
        let now = calendar.date(from: DateComponents(year: 2026, month: 2, day: 20)) ?? Date()
        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.daysRemainingInCycle == 9)
    }

    @Test("Test: category prompt appears for uncategorized-only data")
    func shouldShowCategoryPrompt_whenOnlyUncategorized_returnsTrue() {
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 0,
                    afterBillsBalance: 0,
                    safeDailySpend: 0,
                    daysRemainingInCycle: 1,
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

    @Test("Test: derived alerts are disabled for now")
    func derivedAlerts_whenWeeklyProgressExists_returnsEmpty() {
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 0,
                    afterBillsBalance: 0,
                    safeDailySpend: 0,
                    daysRemainingInCycle: 1,
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
        #expect(viewModel.derivedAlerts.isEmpty)
    }

    @Test("Test: derived alerts skip weekly budget warnings when budget is estimated")
    func derivedAlerts_whenBudgetNotConfigured_doesNotIncludeWeeklyBudgetWarning() {
        let viewModel = DashboardViewModel(
            dataProvider: MockDashboardDataProvider(
                summary: DashboardSummary(
                    currentBalance: 0,
                    afterBillsBalance: 0,
                    safeDailySpend: 0,
                    daysRemainingInCycle: 1,
                    weeklySpending: 95,
                    lastWeekSpending: 80,
                    weeklyBudget: 100,
                    weekDailySpending: Array(repeating: 0, count: 7),
                    topSpendingCategory: "Food",
                    categoryBreakdown: [DashboardCategoryBreakdown(category: "Food", total: 95, ratio: 1)],
                    alerts: [],
                    isWeeklyBudgetUserConfigured: false,
                    recentTransactions: []
                )
            )
        )

        viewModel.load()
        #expect(viewModel.derivedAlerts.isEmpty)
    }

    @Test("Test: configured monthly budget drives weekly budget projection")
    func loadSummary_withConfiguredMonthlyBudget_usesConfiguredWeeklyProjection() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 4_330,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: Date(), recentLimit: 3)
        #expect(abs(summary.weeklyBudget - 1_000) < 0.001)
    }

    @Test("Test: dashboard includes category budget warning alert")
    func loadSummary_whenCategoryNearLimit_includesCategoryBudgetAlert() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let foodID = try categoryRepository.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let now = Date()

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 90,
            currency: "IDR",
            date: now,
            merchantRaw: "Lunch",
            merchantNormalized: "Lunch",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        let defaults = UserDefaults(suiteName: "DashboardBudgetAlertsTests")
        defaults?.removePersistentDomain(forName: "DashboardBudgetAlertsTests")
        let budgetProvider = UserDefaultsCategoryBudgetService(
            defaults: defaults ?? .standard,
            storageKey: "dashboard_budget_alerts_test"
        )
        let monthStart = Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.year, .month], from: now)) ?? now
        try budgetProvider.upsertBudget(category: "Food", amount: 100, monthStartDate: monthStart)

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            ),
            budgetProvider: budgetProvider
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.alerts.contains(where: { $0.title.contains("Food budget warning") }))
    }

    @Test("Test: dashboard current balance includes income transactions")
    func loadSummary_withIncomeTransaction_increasesCurrentBalance() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let incomeCategoryID = try categoryRepository.upsertCategory(name: "Salary", icon: "arrow.down.circle.fill", type: "income")
        let now = Date()

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 500,
            currency: "IDR",
            date: now,
            merchantRaw: "Salary",
            merchantNormalized: "Salary",
            categoryID: incomeCategoryID,
            source: "manual",
            note: nil
        )

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: MockDashboardSettingsProvider(
                budgetWarningThreshold: 80,
                budgetCriticalThreshold: 100,
                defaultMonthlyBudget: 0,
                openingBalance: 0
            )
        )

        let summary = try service.loadSummary(asOf: now, recentLimit: 3)
        #expect(summary.currentBalance == 500)
    }
}
