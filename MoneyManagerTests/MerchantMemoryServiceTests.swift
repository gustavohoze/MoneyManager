import Foundation
import Testing
import CoreData
@testable import Money_Guard

@MainActor
struct MerchantMemoryServiceTests {
    @Test("Test: remembered merchant suggests category")
    func suggestedCategoryID_returnsStoredCategoryForMerchant() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let merchantRepository = CoreDataMerchantRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        _ = try categoryRepository.seedInitialCategories()
        let foodID = try categoryRepository.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()

        let memoryService = MerchantMemoryService(
            merchantRepository: merchantRepository,
            categoryRepository: categoryRepository,
            merchantResolver: MerchantResolver()
        )

        let entryService = TransactionEntryService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            merchantResolver: MerchantResolver(),
            merchantMemoryRecorder: memoryService
        )

        _ = try entryService.saveManualTransaction(
            paymentMethodID: paymentMethodID,
            amount: 45_000,
            currency: "IDR",
            date: Date(),
            merchantRaw: "Starbucks Reserve",
            categoryID: foodID,
            note: nil
        )

        let suggested = try memoryService.suggestedCategoryID(for: "starbucks")
        #expect(suggested == foodID)
    }
}
