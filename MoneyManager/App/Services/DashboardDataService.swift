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
    let daysUntilIncome: Int
    let weeklySpending: Double
    let lastWeekSpending: Double
    let weeklyBudget: Double
    let weekDailySpending: [Double]
    let topSpendingCategory: String
    let categoryBreakdown: [DashboardCategoryBreakdown]
    let alerts: [DashboardAlert]
    let recentTransactions: [DashboardRecentTransaction]
}

protocol DashboardDataProviding {
    func loadSummary(asOf date: Date, recentLimit: Int) throws -> DashboardSummary
}

protocol DashboardSettingsProviding {
    var nextSalaryDate: Date? { get }
    var salaryFrequency: String { get }
}

struct UserDefaultsDashboardSettingsProvider: DashboardSettingsProviding {
    static let nextSalaryDateKey = "settings.nextSalaryDate"
    static let salaryFrequencyKey = "settings.salaryFrequency"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var nextSalaryDate: Date? {
        let timestamp = defaults.double(forKey: Self.nextSalaryDateKey)
        guard timestamp > 0 else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    var salaryFrequency: String {
        defaults.string(forKey: Self.salaryFrequencyKey) ?? "Monthly"
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
            UserDefaultsDashboardSettingsProvider.nextSalaryDateKey,
            UserDefaultsDashboardSettingsProvider.salaryFrequencyKey
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

    init(
        transactionRepository: TransactionRepository,
        categoryRepository: CategoryRepository,
        accountRepository: PaymentMethodRepository,
        settingsProvider: DashboardSettingsProviding = UserDefaultsDashboardSettingsProvider(),
        trendCalculator: DashboardTrendCalculator = DashboardTrendCalculator(),
        categoryInsightCalculator: DashboardCategoryInsightCalculator = DashboardCategoryInsightCalculator(),
        projectionCalculator: DashboardProjectionCalculator = DashboardProjectionCalculator(),
        alertFactory: DashboardAlertFactory = DashboardAlertFactory()
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
        self.settingsProvider = settingsProvider
        self.trendCalculator = trendCalculator
        self.categoryInsightCalculator = categoryInsightCalculator
        self.projectionCalculator = projectionCalculator
        self.alertFactory = alertFactory
    }

    func loadSummary(asOf date: Date = Date(), recentLimit: Int = 3) throws -> DashboardSummary {
        let calendar = Calendar(identifier: .iso8601)
        let windows = DashboardDateWindows(referenceDate: date, calendar: calendar)

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

        let nextIncomeDate = resolveNextIncomeDate(from: windows.asOf, calendar: calendar)
        let daysUntilIncome = max(1, calendar.dateComponents([.day], from: windows.startOfToday, to: nextIncomeDate).day ?? 1)

        let projection = projectionCalculator.makeProjection(
            incomeTotal: incomeTotal,
            expenseTotal: expenseTotal,
            billsLast30Days: billsLast30Days,
            daysUntilIncome: daysUntilIncome,
            weeklySpending: trend.weeklySpending,
            lastWeekSpending: trend.lastWeekSpending
        )

        let alerts = alertFactory.makeAlerts(
            safeDailySpend: projection.safeDailySpend,
            weekDailySpending: trend.weekDailySpending,
            currentWeekByCategory: trend.currentWeekByCategory,
            lastWeekByCategory: trend.lastWeekByCategory,
            currencyText: currencyText
        )

        return DashboardSummary(
            currentBalance: projection.currentBalance,
            afterBillsBalance: projection.afterBillsBalance,
            safeDailySpend: projection.safeDailySpend,
            daysUntilIncome: projection.daysUntilIncome,
            weeklySpending: trend.weeklySpending,
            lastWeekSpending: trend.lastWeekSpending,
            weeklyBudget: projection.weeklyBudget,
            weekDailySpending: trend.weekDailySpending,
            topSpendingCategory: categoryInsights.topCategory,
            categoryBreakdown: categoryInsights.categoryBreakdown,
            alerts: alerts,
            recentTransactions: recent
        )
    }

    private func resolveNextIncomeDate(from date: Date, calendar: Calendar) -> Date {
        let startOfToday = calendar.startOfDay(for: date)
        let storedFrequency = settingsProvider.salaryFrequency

        guard let storedDate = settingsProvider.nextSalaryDate else {
            return calendar.nextDate(
                after: date,
                matching: DateComponents(day: 1),
                matchingPolicy: .nextTime
            ) ?? startOfToday
        }

        var nextDate = calendar.startOfDay(for: storedDate)
        if nextDate >= startOfToday {
            return nextDate
        }

        switch storedFrequency {
        case "Weekly", "Biweekly":
            let intervalDays = storedFrequency == "Weekly" ? 7 : 14
            while nextDate < startOfToday {
                nextDate = calendar.date(byAdding: .day, value: intervalDays, to: nextDate) ?? startOfToday
            }
            return nextDate
        default:
            let payDay = calendar.component(.day, from: nextDate)
            return nextMonthlyPaymentDate(for: payDay, from: startOfToday, calendar: calendar)
        }
    }

    private func nextMonthlyPaymentDate(for payDay: Int, from date: Date, calendar: Calendar) -> Date {
        let clampedPayDay = max(1, min(31, payDay))

        func paymentDate(in monthDate: Date) -> Date {
            let range = calendar.range(of: .day, in: .month, for: monthDate) ?? (1..<29)
            let day = min(clampedPayDay, range.count)
            var components = calendar.dateComponents([.year, .month], from: monthDate)
            components.day = day
            return calendar.date(from: components) ?? monthDate
        }

        let thisMonthDate = paymentDate(in: date)
        if thisMonthDate >= date {
            return thisMonthDate
        }

        let nextMonthAnchor = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        return paymentDate(in: nextMonthAnchor)
    }

    private func currencyText(_ value: Double) -> String {
        AppCurrency.formatted(value)
    }
}
