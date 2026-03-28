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
        let settingsProvider = UserDefaultsDashboardSettingsProvider(defaults: defaults)
        let categoryBudgetService = UserDefaultsCategoryBudgetService(defaults: defaults)
        
        let dashboardDataService = DashboardDataService(
            transactionRepository: transactionRepo,
            categoryRepository: categoryRepo,
            accountRepository: accountRepo,
            settingsProvider: settingsProvider,
            budgetProvider: categoryBudgetService
        )
        
        // Measure performance of loading summary
        self.measure {
            do {
                let summary = try dashboardDataService.loadSummary(asOf: today, recentLimit: 3)
                XCTAssertGreaterThan(summary.recentTransactions.count, 0)
            } catch {
                XCTFail("Failed to load summary: \(error)")
            }
        }
    }
}
