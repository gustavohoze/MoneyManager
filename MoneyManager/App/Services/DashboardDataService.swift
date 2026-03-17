import Foundation
import CoreData
import Combine

struct DashboardRecentTransaction: Equatable {
    let id: UUID
    let merchant: String
    let category: String
    let categoryIcon: String
    let account: String
    let amount: Double
    let date: Date
}

struct DashboardCategoryBreakdown: Equatable {
    let category: String
    let total: Double
    let ratio: Double
}

struct DashboardAlert: Equatable {
    let title: String
    let detail: String
}

struct DashboardSummary: Equatable {
    let currentBalance: Double
    let afterBillsBalance: Double
    let safeDailySpend: Double
    let daysRemainingInCycle: Int
    let weeklySpending: Double
    let lastWeekSpending: Double
    let weeklyBudget: Double
    let weekDailySpending: [Double]
    let topSpendingCategory: String
    let categoryBreakdown: [DashboardCategoryBreakdown]
    let alerts: [DashboardAlert]
    let isWeeklyBudgetUserConfigured: Bool
    let budgetWarningThreshold: Int
    let budgetCriticalThreshold: Int
    let recentTransactions: [DashboardRecentTransaction]

    init(
        currentBalance: Double,
        afterBillsBalance: Double,
        safeDailySpend: Double,
        daysRemainingInCycle: Int,
        weeklySpending: Double,
        lastWeekSpending: Double,
        weeklyBudget: Double,
        weekDailySpending: [Double],
        topSpendingCategory: String,
        categoryBreakdown: [DashboardCategoryBreakdown],
        alerts: [DashboardAlert],
        isWeeklyBudgetUserConfigured: Bool = true,
        budgetWarningThreshold: Int = 80,
        budgetCriticalThreshold: Int = 100,
        recentTransactions: [DashboardRecentTransaction]
    ) {
        self.currentBalance = currentBalance
        self.afterBillsBalance = afterBillsBalance
        self.safeDailySpend = safeDailySpend
        self.daysRemainingInCycle = daysRemainingInCycle
        self.weeklySpending = weeklySpending
        self.lastWeekSpending = lastWeekSpending
        self.weeklyBudget = weeklyBudget
        self.weekDailySpending = weekDailySpending
        self.topSpendingCategory = topSpendingCategory
        self.categoryBreakdown = categoryBreakdown
        self.alerts = alerts
        self.isWeeklyBudgetUserConfigured = isWeeklyBudgetUserConfigured
        self.budgetWarningThreshold = budgetWarningThreshold
        self.budgetCriticalThreshold = budgetCriticalThreshold
        self.recentTransactions = recentTransactions
    }
}

protocol DashboardDataProviding {
    func loadSummary(asOf date: Date, recentLimit: Int) throws -> DashboardSummary
}

protocol DashboardSettingsProviding {
    var budgetWarningThreshold: Int { get }
    var budgetCriticalThreshold: Int { get }
    var defaultMonthlyBudget: Double { get }
    var openingBalance: Double { get }
}

struct UserDefaultsDashboardSettingsProvider: DashboardSettingsProviding {
    static let defaultMonthlyBudgetKey = "settings.defaultMonthlyBudget"
    static let openingBalanceKey = "settings.openingBalance"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var budgetWarningThreshold: Int {
        let stored = defaults.integer(forKey: "settings.budgetWarningThreshold")
        return (50...95).contains(stored) ? stored : 80
    }

    var budgetCriticalThreshold: Int {
        let stored = defaults.integer(forKey: "settings.budgetCriticalThreshold")
        return (80...150).contains(stored) ? stored : 100
    }

    var defaultMonthlyBudget: Double {
        let value = defaults.double(forKey: Self.defaultMonthlyBudgetKey)
        return max(value, 0)
    }

    var openingBalance: Double {
        defaults.double(forKey: Self.openingBalanceKey)
    }
}

protocol DashboardRefreshTriggering {
    var updates: AnyPublisher<Void, Never> { get }
}

struct UserDefaultsDashboardRefreshTrigger: DashboardRefreshTriggering {
    let updates: AnyPublisher<Void, Never>

    init(
        defaults: UserDefaults = .standard,
        center: NotificationCenter = .default,
        observedKeys: Set<String> = [
            AppCurrency.settingsKey,
            UserDefaultsDashboardSettingsProvider.defaultMonthlyBudgetKey,
            UserDefaultsDashboardSettingsProvider.openingBalanceKey,
            "settings.budgetWarningThreshold",
            "settings.budgetCriticalThreshold"
        ]
    ) {
        let initialSignature = Self.signature(defaults: defaults, keys: observedKeys)
        updates = center
            .publisher(for: UserDefaults.didChangeNotification, object: defaults)
            .map { _ in Self.signature(defaults: defaults, keys: observedKeys) }
            .prepend(initialSignature)
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private static func signature(defaults: UserDefaults, keys: Set<String>) -> String {
        keys.sorted().map { key in
            let value = defaults.object(forKey: key)
            return "\(key)=\(String(describing: value))"
        }.joined(separator: "|")
    }
}

struct DashboardDataService: DashboardDataProviding {
    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let accountRepository: PaymentMethodRepository
    private let settingsProvider: DashboardSettingsProviding
    private let trendCalculator: DashboardTrendCalculator
    private let categoryInsightCalculator: DashboardCategoryInsightCalculator
    private let projectionCalculator: DashboardProjectionCalculator
    private let alertFactory: DashboardAlertFactory
    private let budgetProvider: CategoryBudgetProviding

    init(
        transactionRepository: TransactionRepository,
        categoryRepository: CategoryRepository,
        accountRepository: PaymentMethodRepository,
        settingsProvider: DashboardSettingsProviding = UserDefaultsDashboardSettingsProvider(),
        trendCalculator: DashboardTrendCalculator = DashboardTrendCalculator(),
        categoryInsightCalculator: DashboardCategoryInsightCalculator = DashboardCategoryInsightCalculator(),
        projectionCalculator: DashboardProjectionCalculator = DashboardProjectionCalculator(),
        alertFactory: DashboardAlertFactory = DashboardAlertFactory(),
        budgetProvider: CategoryBudgetProviding = NoOpCategoryBudgetService()
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
        self.settingsProvider = settingsProvider
        self.trendCalculator = trendCalculator
        self.categoryInsightCalculator = categoryInsightCalculator
        self.projectionCalculator = projectionCalculator
        self.alertFactory = alertFactory
        self.budgetProvider = budgetProvider
    }

    func loadSummary(asOf date: Date = Date(), recentLimit: Int = 3) throws -> DashboardSummary {
        let calendar = Calendar(identifier: .iso8601)
        let windows = DashboardDateWindows(referenceDate: date, calendar: calendar)
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: windows.asOf)) ?? windows.startOfToday

        let allTransactions = try transactionRepository.fetchTransactions()
        let monthWindowTransactions = try transactionRepository.fetchTransactions(
            from: windows.startOfMonthWindow,
            to: windows.asOf
        )
        let recentTransactions = try transactionRepository.fetchRecentTransactions(limit: recentLimit)
        let categories = try categoryRepository.fetchCategories()
        let accounts = try accountRepository.fetchPaymentMethods()

        let categoryByID = categories.reduce(into: [UUID: (name: String, type: String, icon: String)]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String,
                let type = object.value(forKey: "type") as? String
            else {
                return
            }

            let icon = (object.value(forKey: "icon") as? String) ?? DashboardDomainConstants.defaultCategoryIcon
            partialResult[id] = (name, type, icon)
        }

        let accountByID = accounts.reduce(into: [UUID: String]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String
            else {
                return
            }
            partialResult[id] = name
        }

        var incomeTotal = 0.0
        var expenseTotal = 0.0
        var expenseByCategory = [String: Double]()
        var expenseEntries: [(amount: Double, date: Date, category: String)] = []
        var expenseByCategoryCurrentMonth = [String: Double]()
        var billsLast30Days = 0.0

        for object in allTransactions {
            let amount = (object.value(forKey: "amount") as? Double) ?? 0
            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let categoryID = object.value(forKey: "categoryID") as? UUID
            let categoryInfo = categoryID.flatMap { categoryByID[$0] }

            let categoryType = categoryInfo?.type.lowercased() ?? DashboardDomainConstants.expenseType
            if categoryType == DashboardDomainConstants.incomeType {
                incomeTotal += amount
            } else {
                expenseTotal += amount
                let categoryName = categoryInfo?.name ?? DashboardDomainConstants.uncategorized
                expenseByCategory[categoryName, default: 0] += amount
                expenseEntries.append((amount: amount, date: transactionDate, category: categoryName))
                if transactionDate >= startOfCurrentMonth && transactionDate <= windows.asOf {
                    expenseByCategoryCurrentMonth[categoryName, default: 0] += amount
                }
            }
        }

        for object in monthWindowTransactions {
            let amount = (object.value(forKey: "amount") as? Double) ?? 0
            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let categoryID = object.value(forKey: "categoryID") as? UUID
            let categoryInfo = categoryID.flatMap { categoryByID[$0] }
            let categoryType = categoryInfo?.type.lowercased() ?? DashboardDomainConstants.expenseType
            if categoryType == DashboardDomainConstants.expenseType,
               categoryInfo?.name == DashboardDomainConstants.billsCategory,
               transactionDate >= windows.startOfMonthWindow,
               transactionDate <= windows.asOf {
                billsLast30Days += amount
            }
        }

        let trend = trendCalculator.makeTrend(expenses: expenseEntries, windows: windows, calendar: calendar)
        let categoryInsights = categoryInsightCalculator.makeInsights(
            expenseByCategory: expenseByCategory,
            expenseTotal: expenseTotal
        )

        let recent = recentTransactions.compactMap { object -> DashboardRecentTransaction? in
            guard let id = object.value(forKey: "id") as? UUID else {
                return nil
            }
            let normalized = (object.value(forKey: "merchantNormalized") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let raw = (object.value(forKey: "merchantRaw") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let merchant = !normalized.isEmpty ? normalized : (!raw.isEmpty ? raw : DashboardDomainConstants.unknown)
            let amount = (object.value(forKey: "amount") as? Double) ?? 0
            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let categoryName = (object.value(forKey: "categoryID") as? UUID).flatMap { categoryByID[$0]?.name } ?? DashboardDomainConstants.uncategorized
            let categoryIcon = (object.value(forKey: "categoryID") as? UUID).flatMap { categoryByID[$0]?.icon } ?? DashboardDomainConstants.defaultCategoryIcon
            let accountName = (object.value(forKey: "paymentMethodID") as? UUID).flatMap { accountByID[$0] } ?? DashboardDomainConstants.unknown

            return DashboardRecentTransaction(
                id: id,
                merchant: merchant,
                category: categoryName,
                categoryIcon: categoryIcon,
                account: accountName,
                amount: amount,
                date: transactionDate
            )
        }

        let daysRemainingInCycle = max(1, daysRemainingInCurrentMonth(from: windows.asOf, calendar: calendar))

        let projection = projectionCalculator.makeProjection(
            openingBalance: settingsProvider.openingBalance,
            incomeTotal: incomeTotal,
            expenseTotal: expenseTotal,
            billsLast30Days: billsLast30Days,
            daysRemainingInCycle: daysRemainingInCycle,
            weeklySpending: trend.weeklySpending,
            lastWeekSpending: trend.lastWeekSpending,
            defaultMonthlyBudget: settingsProvider.defaultMonthlyBudget
        )

        var alerts = alertFactory.makeAlerts(
            safeDailySpend: projection.safeDailySpend,
            weekDailySpending: trend.weekDailySpending,
            currentWeekByCategory: trend.currentWeekByCategory,
            lastWeekByCategory: trend.lastWeekByCategory,
            currencyText: currencyText
        )
        alerts.append(
            contentsOf: makeCategoryBudgetAlerts(
                monthStartDate: startOfCurrentMonth,
                currentMonthSpendByCategory: expenseByCategoryCurrentMonth,
                warningThreshold: settingsProvider.budgetWarningThreshold,
                criticalThreshold: settingsProvider.budgetCriticalThreshold
            )
        )

        return DashboardSummary(
            currentBalance: projection.currentBalance,
            afterBillsBalance: projection.afterBillsBalance,
            safeDailySpend: projection.safeDailySpend,
            daysRemainingInCycle: projection.daysRemainingInCycle,
            weeklySpending: trend.weeklySpending,
            lastWeekSpending: trend.lastWeekSpending,
            weeklyBudget: projection.weeklyBudget,
            weekDailySpending: trend.weekDailySpending,
            topSpendingCategory: categoryInsights.topCategory,
            categoryBreakdown: categoryInsights.categoryBreakdown,
            alerts: alerts,
            isWeeklyBudgetUserConfigured: settingsProvider.defaultMonthlyBudget > 0,
            budgetWarningThreshold: settingsProvider.budgetWarningThreshold,
            budgetCriticalThreshold: settingsProvider.budgetCriticalThreshold,
            recentTransactions: recent
        )
    }

    private func daysRemainingInCurrentMonth(from date: Date, calendar: Calendar) -> Int {
        guard
            let range = calendar.range(of: .day, in: .month, for: date)
        else {
            return 1
        }
        let day = calendar.component(.day, from: date)
        return max(1, range.count - day + 1)
    }

    private func makeCategoryBudgetAlerts(
        monthStartDate: Date,
        currentMonthSpendByCategory: [String: Double],
        warningThreshold: Int,
        criticalThreshold: Int
    ) -> [DashboardAlert] {
        let resolvedBudgets = budgetProvider.resolvedBudgets(for: monthStartDate)
        guard !resolvedBudgets.isEmpty else {
            return []
        }

        let warningRatio = Double(warningThreshold) / 100
        let criticalRatio = Double(criticalThreshold) / 100

        let sortedAlerts = resolvedBudgets.compactMap { budget -> (Double, DashboardAlert)? in
            guard budget.amount > 0 else {
                return nil
            }

            let spent = currentMonthSpendByCategory[budget.category, default: 0]
            let ratio = spent / budget.amount

            if ratio >= criticalRatio {
                return (
                    ratio,
                    DashboardAlert(
                        title: "⚠︎ \(budget.category) budget exceeded",
                        detail: "Spent \(currencyText(spent)) vs budget \(currencyText(budget.amount)) this month."
                    )
                )
            }

            if ratio >= warningRatio {
                let remaining = max(budget.amount - spent, 0)
                return (
                    ratio,
                    DashboardAlert(
                        title: "⚠︎ \(budget.category) budget warning",
                        detail: "\(Int(ratio * 100))% used. Remaining \(currencyText(remaining))."
                    )
                )
            }

            return nil
        }
        .sorted { $0.0 > $1.0 }
        .prefix(3)

        return sortedAlerts.map { $0.1 }
    }

    private func currencyText(_ value: Double) -> String {
        AppCurrency.formatted(value)
    }
}
