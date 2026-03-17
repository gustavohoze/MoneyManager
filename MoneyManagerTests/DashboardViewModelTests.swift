import Foundation
import Testing
import CoreData
@testable import MoneyManager

@MainActor
struct DashboardViewModelTests {
    @Test("Test: dashboard summary calculations")
    func load_withSeedData_computesBalanceWeeklyAndTopCategory() throws {
        // Objective: Validate Milestone 1 dashboard numbers from repository-backed data.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let foodID = try categoryRepository.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let transportID = try categoryRepository.upsertCategory(name: "Transport", icon: "car.fill", type: "expense")
        let incomeID = try categoryRepository.upsertCategory(name: "Salary", icon: "banknote", type: "income")

        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now) ?? now
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: now) ?? now

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 1_000,
            currency: "IDR",
            date: now,
            merchantRaw: "Company",
            merchantNormalized: "Company",
            categoryID: incomeID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 200,
            currency: "IDR",
            date: now,
            merchantRaw: "Lunch",
            merchantNormalized: "Lunch",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 300,
            currency: "IDR",
            date: twoDaysAgo,
            merchantRaw: "Ride",
            merchantNormalized: "Ride",
            categoryID: transportID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 50,
            currency: "IDR",
            date: tenDaysAgo,
            merchantRaw: "Snack",
            merchantNormalized: "Snack",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        let service = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let viewModel = DashboardViewModel(dataProvider: service)

        viewModel.load(asOf: now)

        #expect(viewModel.currentBalance == 450)
        #expect(viewModel.weeklySpending == 500)
        #expect(viewModel.topSpendingCategory == "Transport")
        #expect(viewModel.lastWeekSpending == 0)
        #expect(viewModel.weekDailySpending.count == 7)
        #expect(viewModel.afterBillsBalance <= viewModel.currentBalance)
        #expect(viewModel.recentTransactions.count == 3)
        #expect(viewModel.recentTransactions.first?.account.isEmpty == false)
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
}
