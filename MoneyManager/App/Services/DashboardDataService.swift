import Foundation
import CoreData

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

struct DashboardDataService: DashboardDataProviding {
    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let accountRepository: PaymentMethodRepository

    init(
        transactionRepository: TransactionRepository,
        categoryRepository: CategoryRepository,
        accountRepository: PaymentMethodRepository
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
    }

    func loadSummary(asOf date: Date = Date(), recentLimit: Int = 3) throws -> DashboardSummary {
        let transactions = try transactionRepository.fetchTransactions()
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

            let icon = (object.value(forKey: "icon") as? String) ?? "questionmark.circle"
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
        var weeklySpending = 0.0
        var lastWeekSpending = 0.0
        var expenseByCategory = [String: Double]()
        var weekDailySpending = Array(repeating: 0.0, count: 7)
        var lastWeekByCategory = [String: Double]()
        var currentWeekByCategory = [String: Double]()
        var billsLast30Days = 0.0

        let calendar = Calendar(identifier: .iso8601)
        let startOfToday = calendar.startOfDay(for: date)
        let startOfWindow = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let startOfLastWeek = calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
        let endOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday) ?? startOfToday
        let startOfMonthWindow = calendar.date(byAdding: .day, value: -30, to: startOfToday) ?? startOfToday

        for object in transactions {
            let amount = (object.value(forKey: "amount") as? Double) ?? 0
            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let categoryID = object.value(forKey: "categoryID") as? UUID
            let categoryInfo = categoryID.flatMap { categoryByID[$0] }

            let categoryType = categoryInfo?.type.lowercased() ?? "expense"
            if categoryType == "income" {
                incomeTotal += amount
            } else {
                expenseTotal += amount

                if categoryInfo?.name == "Bills", transactionDate >= startOfMonthWindow && transactionDate <= date {
                    billsLast30Days += amount
                }

                if transactionDate >= startOfWindow && transactionDate <= date {
                    weeklySpending += amount
                    let dayOffset = calendar.dateComponents([.day], from: startOfWindow, to: transactionDate).day ?? 0
                    if (0..<7).contains(dayOffset) {
                        weekDailySpending[dayOffset] += amount
                    }
                }

                if transactionDate >= startOfLastWeek && transactionDate <= endOfLastWeek {
                    lastWeekSpending += amount
                }

                let categoryName = categoryInfo?.name ?? "Uncategorized"
                expenseByCategory[categoryName, default: 0] += amount

                if transactionDate >= startOfWindow && transactionDate <= date {
                    currentWeekByCategory[categoryName, default: 0] += amount
                } else if transactionDate >= startOfLastWeek && transactionDate <= endOfLastWeek {
                    lastWeekByCategory[categoryName, default: 0] += amount
                }
            }
        }

        let topCategory = expenseByCategory.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        })?.key ?? "Uncategorized"

        let recent = transactions.prefix(recentLimit).compactMap { object -> DashboardRecentTransaction? in
            guard let id = object.value(forKey: "id") as? UUID else {
                return nil
            }
            let normalized = (object.value(forKey: "merchantNormalized") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let raw = (object.value(forKey: "merchantRaw") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let merchant = !normalized.isEmpty ? normalized : (!raw.isEmpty ? raw : "Unknown")
            let amount = (object.value(forKey: "amount") as? Double) ?? 0
            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let categoryName = (object.value(forKey: "categoryID") as? UUID).flatMap { categoryByID[$0]?.name } ?? "Uncategorized"
            let categoryIcon = (object.value(forKey: "categoryID") as? UUID).flatMap { categoryByID[$0]?.icon } ?? "questionmark.circle"
            let accountName = (object.value(forKey: "paymentMethodID") as? UUID).flatMap { accountByID[$0] } ?? "Unknown"

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

        let weeklyBudget = max(weeklySpending, lastWeekSpending, 1) * 1.2
        let nextIncomeDate = calendar.nextDate(
            after: date,
            matching: DateComponents(day: 1),
            matchingPolicy: .nextTime
        ) ?? date
        let daysUntilIncome = max(1, calendar.dateComponents([.day], from: startOfToday, to: nextIncomeDate).day ?? 1)
        let upcomingBills = billsLast30Days / 30 * Double(daysUntilIncome)
        let afterBillsBalance = currentBalance(income: incomeTotal, expense: expenseTotal) - upcomingBills
        let safeDailySpend = max(afterBillsBalance, 0) / Double(daysUntilIncome)

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

        if alerts.count > 2 {
            alerts = Array(alerts.prefix(2))
        }

        return DashboardSummary(
            currentBalance: currentBalance(income: incomeTotal, expense: expenseTotal),
            afterBillsBalance: afterBillsBalance,
            safeDailySpend: safeDailySpend,
            daysUntilIncome: daysUntilIncome,
            weeklySpending: weeklySpending,
            lastWeekSpending: lastWeekSpending,
            weeklyBudget: weeklyBudget,
            weekDailySpending: weekDailySpending,
            topSpendingCategory: topCategory,
            categoryBreakdown: categoryBreakdown,
            alerts: alerts,
            recentTransactions: recent
        )
    }

    private func currentBalance(income: Double, expense: Double) -> Double {
        income - expense
    }

    private func currencyText(_ value: Double) -> String {
        value.formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }
}
