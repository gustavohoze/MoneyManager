import Foundation
import Testing
import CoreData
@testable import Money_Guard

@MainActor
struct TransactionEntryServiceTests {
    @Test("Test: invalid amount is rejected")
    func saveManualTransaction_zeroAmount_throwsValidationError() throws {
        // Objective: Enforce Milestone 1 amount validation rule.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let service = TransactionEntryService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            merchantResolver: MerchantResolver()
        )
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()

        #expect(throws: TransactionEntryError.self) {
            _ = try service.saveManualTransaction(
                paymentMethodID: paymentMethodID,
                amount: 0,
                currency: "IDR",
                date: Date(),
                merchantRaw: "Coffee",
                categoryID: nil,
                note: nil
            )
        }
    }

    @Test("Test: missing merchant and category fallback")
    func saveManualTransaction_missingMerchantAndCategory_usesFallbacksAndTracksAnalytics() throws {
        // Objective: Ensure Unknown merchant and Uncategorized category are auto-applied.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let analytics = InMemoryAnalyticsService()
        let service = TransactionEntryService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            merchantResolver: MerchantResolver(),
            analytics: analytics
        )
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()

        let result = try service.saveManualTransaction(
            paymentMethodID: paymentMethodID,
            amount: 45_000,
            currency: "IDR",
            date: Date(),
            merchantRaw: "   ",
            categoryID: nil,
            note: "Lunch"
        )

        #expect(result.duplicateDetected == false)
        #expect(analytics.allEvents() == [.transactionCreated])

        let transactions = try transactionRepository.fetchTransactions()
        #expect(transactions.count == 1)

        let transaction = try #require(transactions.first)
        let merchantRaw = transaction.value(forKey: "merchantRaw") as? String
        let assignedCategoryID = transaction.value(forKey: "categoryID") as? UUID

        #expect(merchantRaw == "Unknown")
        #expect(assignedCategoryID != nil)

        let categories = try categoryRepository.fetchCategories()
        let uncategorized = categories.first { ($0.value(forKey: "name") as? String) == "Uncategorized" }
        #expect(uncategorized != nil)
    }

    @Test("Test: duplicate warning is non-blocking")
    func saveManualTransaction_duplicateStillSaves() throws {
        // Objective: Detect duplicates without blocking save.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let service = TransactionEntryService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            merchantResolver: MerchantResolver()
        )
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let date = Date()

        let first = try service.saveManualTransaction(
            paymentMethodID: paymentMethodID,
            amount: 9_000,
            currency: "IDR",
            date: date,
            merchantRaw: "Grab",
            categoryID: nil,
            note: nil
        )
        let second = try service.saveManualTransaction(
            paymentMethodID: paymentMethodID,
            amount: 9_000,
            currency: "IDR",
            date: date,
            merchantRaw: "grab",
            categoryID: nil,
            note: nil
        )

        #expect(first.duplicateDetected == false)
        #expect(second.duplicateDetected == true)

        let transactions = try transactionRepository.fetchTransactions()
        #expect(transactions.count == 2)
    }
}
