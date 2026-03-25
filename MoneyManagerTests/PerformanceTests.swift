import XCTest
import CoreData
@testable import Money_Guard

final class PerformanceTests: XCTestCase {
    
    @MainActor
    func testDashboardAggregationPerformance() throws {
        // Objective: Measure the time required to fetch and aggregate 5,000 transactions on the Dashboard.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let categoryRepo = CoreDataCategoryRepository(context: context)
        
        let account = try accountRepo.ensureDefaultPaymentMethod()
        let category = try categoryRepo.seedInitialCategories()
        
        // Seed 5,000 transactions
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<5000 {
            let offsetDate = calendar.date(byAdding: .hour, value: -(i % 720), to: today)! // Spread over 30 days
            _ = try transactionRepo.createTransaction(
                paymentMethodID: account,
                amount: Double.random(in: 10_000...500_000),
                currency: "IDR",
                date: offsetDate,
                merchantRaw: "Merchant \(i % 100)",
                merchantNormalized: "Merchant \(i % 100)",
                categoryID: nil,
                source: "manual",
                note: nil
            )
        }
        
        // Setup service
        let defaults = UserDefaults(suiteName: "PerformanceTests")!
        let alertsSettingsService = DefaultAlertsSettingsService(userDefaults: defaults)
        let accountsSettingsService = DefaultAccountsAndIncomeSettingsService(userDefaults: defaults)
        let categoryBudgetService = DefaultCategoryBudgetService(context: context)
        
        let dashboardDataService = DefaultDashboardDataService(
            transactionRepository: transactionRepo,
            categoryRepository: categoryRepo,
            paymentMethodRepository: accountRepo,
            alertsSettingsService: alertsSettingsService,
            accountsSettingsService: accountsSettingsService,
            categoryBudgetService: categoryBudgetService,
            dateGenerator: { today }
        )
        
        // Measure performance of computing summary
        self.measure {
            let expectation = self.expectation(description: "Computation finished")
            Task {
                let summary = try await dashboardDataService.computeSummary()
                XCTAssertGreaterThan(summary.recentTransactions.count, 0)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
