import CoreData
import Testing
@testable import Money_Guard

@MainActor
struct RepositoryTests {
    @Test("Test: invalid account")
    func createTransaction_invalidAccount_throwsError() throws {
        // Objective: Ensure transaction creation fails for non-existent account references.
        // Given: An in-memory transaction repository and a random account ID.
        // When: createTransaction is called with that unknown account ID.
        // Then: The repository throws a validation error.
        let context = PersistenceController(inMemory: true).container.viewContext
        let repo = CoreDataTransactionRepository(context: context)

        #expect(throws: CoreDataRepositoryError.self) {
            _ = try repo.createTransaction(
                paymentMethodID: UUID(),
                amount: 20,
                currency: "USD",
                date: Date(),
                merchantRaw: "Cafe",
                merchantNormalized: "Cafe",
                categoryID: nil,
                source: "manual",
                note: nil
            )
        }
    }

    @Test("Test: negative amount")
    func createTransaction_negativeAmount_throwsValidationError() throws {
        // Objective: Prevent negative transaction amounts from being persisted.
        // Given: A valid default account in an in-memory store.
        // When: createTransaction is called with a negative amount.
        // Then: The repository throws a validation error.
        let controller = PersistenceController(inMemory: true)
        let accountRepo = CoreDataPaymentMethodRepository(context: controller.container.viewContext)
        let transactionRepo = CoreDataTransactionRepository(context: controller.container.viewContext)
        let paymentMethodID = try accountRepo.ensureDefaultPaymentMethod()

        #expect(throws: CoreDataRepositoryError.self) {
            _ = try transactionRepo.createTransaction(
                paymentMethodID: paymentMethodID,
                amount: -10,
                currency: "USD",
                date: Date(),
                merchantRaw: "Cafe",
                merchantNormalized: "Cafe",
                categoryID: nil,
                source: "manual",
                note: nil
            )
        }
    }

    @Test("Test: seed categories")
    func seedCategories_firstLaunch_insertsDefaults() throws {
        // Objective: Seed default categories once and keep operation idempotent.
        // Given: An empty in-memory category repository.
        // When: seedInitialCategories is called twice.
        // Then: First insert adds categories, second adds none, total is at least 8.
        let context = PersistenceController(inMemory: true).container.viewContext
        let repo = CoreDataCategoryRepository(context: context)

        let firstInsert = try repo.seedInitialCategories()
        let secondInsert = try repo.seedInitialCategories()
        let categories = try repo.fetchCategories()

        #expect(firstInsert > 0)
        #expect(secondInsert == 0)
        #expect(categories.count >= 8)
    }

    @Test("Test: second launch")
    func seedCategories_secondLaunch_doesNotDuplicate() throws {
        // Objective: Avoid duplicate categories caused by spacing/case variations.
        // Given: A repository with an existing "Food" category.
        // When: upsertCategory is called again with " food ".
        // Then: The same ID is returned and only one normalized "food" category exists.
        let context = PersistenceController(inMemory: true).container.viewContext
        let repo = CoreDataCategoryRepository(context: context)

        let first = try repo.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let second = try repo.upsertCategory(name: " food ", icon: "fork.knife", type: "expense")
        let categories = try repo.fetchCategories().filter { ($0.value(forKey: "name") as? String)?.lowercased() == "food" }

        #expect(first == second)
        #expect(categories.count == 1)
    }

    @Test("Test: deduplicate categories and remap transactions")
    func deduplicateCategories_remapsTransactionsToCanonicalCategory() throws {
        // Objective: Ensure duplicate categories are merged and existing transactions keep valid category references.
        // Given: Two Category rows with equivalent names and one transaction linked to the duplicate category.
        // When: Categories are fetched through the repository.
        // Then: Only one category remains for that name and the transaction points to the kept category ID.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let categoryRepo = CoreDataCategoryRepository(context: context)
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)

        let canonicalID = UUID()
        let duplicateID = UUID()

        let canonical = NSManagedObject(entity: try #require(NSEntityDescription.entity(forEntityName: "Category", in: context)), insertInto: context)
        canonical.setValue(canonicalID, forKey: "id")
        canonical.setValue("Food", forKey: "name")
        canonical.setValue("fork.knife", forKey: "icon")
        canonical.setValue("expense", forKey: "type")

        let duplicate = NSManagedObject(entity: try #require(NSEntityDescription.entity(forEntityName: "Category", in: context)), insertInto: context)
        duplicate.setValue(duplicateID, forKey: "id")
        duplicate.setValue(" food ", forKey: "name")
        duplicate.setValue("fork.knife", forKey: "icon")
        duplicate.setValue("expense", forKey: "type")

        try context.save()

        let paymentMethodID = try accountRepo.ensureDefaultPaymentMethod()
        let transactionID = try transactionRepo.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 42,
            currency: "USD",
            date: Date(),
            merchantRaw: "Cafe",
            merchantNormalized: "Cafe",
            categoryID: duplicateID,
            source: "manual",
            note: nil
        )

        let categories = try categoryRepo.fetchCategories()
        let foodCategories = categories.filter {
            (($0.value(forKey: "name") as? String)?.lowercased() == "food")
        }
        let resolvedFoodID = foodCategories.first?.value(forKey: "id") as? UUID
        let transaction = try transactionRepo.fetchTransaction(id: transactionID)
        let transactionCategoryID = transaction.value(forKey: "categoryID") as? UUID

        #expect(foodCategories.count == 1)
        #expect(resolvedFoodID != nil)
        #expect(transactionCategoryID == resolvedFoodID)
    }

    @Test("Test: update category")
    func updateCategory_changesNameAndType() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let repo = CoreDataCategoryRepository(context: context)

        let categoryID = try repo.upsertCategory(name: "Other", icon: "questionmark.circle", type: "expense")
        try repo.updateCategory(id: categoryID, name: "Salary", icon: "arrow.down.circle.fill", type: "income")

        let updated = try repo.fetchCategory(id: categoryID)
        #expect((updated.value(forKey: "name") as? String) == "Salary")
        #expect((updated.value(forKey: "type") as? String) == "income")
    }

    @Test("Test: delete category remaps transactions")
    func deleteCategory_remapsTransactionsToFallback() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let categoryRepo = CoreDataCategoryRepository(context: context)
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)

        let oldCategoryID = try categoryRepo.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let fallbackCategoryID = try categoryRepo.upsertCategory(name: "Uncategorized", icon: "questionmark.circle", type: "expense")
        let accountID = try accountRepo.ensureDefaultPaymentMethod()

        let transactionID = try transactionRepo.createTransaction(
            paymentMethodID: accountID,
            amount: 25,
            currency: "USD",
            date: Date(),
            merchantRaw: "Cafe",
            merchantNormalized: "Cafe",
            categoryID: oldCategoryID,
            source: "manual",
            note: nil
        )

        try categoryRepo.deleteCategory(id: oldCategoryID, remapTransactionsTo: fallbackCategoryID)

        let transaction = try transactionRepo.fetchTransaction(id: transactionID)
        let categoryID = transaction.value(forKey: "categoryID") as? UUID
        #expect(categoryID == fallbackCategoryID)

        #expect(throws: CoreDataRepositoryError.self) {
            _ = try categoryRepo.fetchCategory(id: oldCategoryID)
        }
    }

    @Test("Test: validates transaction source")
    func createTransaction_invalidSource_throwsError() throws {
        // Objective: Enforce allowed transaction source values.
        // Given: A valid account and transaction repository.
        // When: createTransaction is called with an unsupported source.
        // Then: The repository throws a validation error.
        let controller = PersistenceController(inMemory: true)
        let accountRepo = CoreDataPaymentMethodRepository(context: controller.container.viewContext)
        let repo = CoreDataTransactionRepository(context: controller.container.viewContext)
        let paymentMethodID = try accountRepo.ensureDefaultPaymentMethod()

        #expect(throws: CoreDataRepositoryError.self) {
            _ = try repo.createTransaction(
                paymentMethodID: paymentMethodID,
                amount: 10,
                currency: "USD",
                date: Date(),
                merchantRaw: "Cafe",
                merchantNormalized: "Cafe",
                categoryID: nil,
                source: "invalid_source",
                note: nil
            )
        }
    }

    @Test("Test: fetchTransactions(paymentMethodID)")
    func fetchTransactions_paymentMethodID_returnsOnlyMatchingAccount() throws {
        // Objective: Return only transactions for the requested account.
        // Given: PaymentMethod A has two transactions and PaymentMethod B has one.
        // When: fetchTransactions(paymentMethodID: accountA) is executed.
        // Then: Exactly two transactions are returned.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)

        let accountA = try accountRepo.upsertPaymentMethod(name: "A", type: "bank", currency: "USD")
        let accountB = try accountRepo.upsertPaymentMethod(name: "B", type: "bank", currency: "USD")

        _ = try transactionRepo.createTransaction(paymentMethodID: accountA, amount: 10, currency: "USD", date: Date(), merchantRaw: "Cafe", merchantNormalized: "Cafe", categoryID: nil, source: "manual", note: nil)
        _ = try transactionRepo.createTransaction(paymentMethodID: accountA, amount: 20, currency: "USD", date: Date(), merchantRaw: "Store", merchantNormalized: "Store", categoryID: nil, source: "manual", note: nil)
        _ = try transactionRepo.createTransaction(paymentMethodID: accountB, amount: 30, currency: "USD", date: Date(), merchantRaw: "Bus", merchantNormalized: "Bus", categoryID: nil, source: "manual", note: nil)

        let forA = try transactionRepo.fetchTransactions(paymentMethodID: accountA)
        #expect(forA.count == 2)
    }

    @Test("Test: fetchTransactions(dateRange)")
    func fetchTransactions_dateRange_returnsOnlyInRange() throws {
        // Objective: Filter transactions by a bounded date range.
        // Given: One in-range transaction and one out-of-range transaction.
        // When: fetchTransactions(from: start, to: end) is called.
        // Then: Only the in-range transaction is returned.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let account = try accountRepo.ensureDefaultPaymentMethod()

        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        let within = now
        let outside = calendar.date(byAdding: .day, value: -40, to: now)!

        _ = try transactionRepo.createTransaction(paymentMethodID: account, amount: 10, currency: "USD", date: within, merchantRaw: "Cafe", merchantNormalized: "Cafe", categoryID: nil, source: "manual", note: nil)
        _ = try transactionRepo.createTransaction(paymentMethodID: account, amount: 10, currency: "USD", date: outside, merchantRaw: "Old", merchantNormalized: "Old", categoryID: nil, source: "manual", note: nil)

        let start = calendar.date(byAdding: .day, value: -7, to: now)!
        let end = now
        let filtered = try transactionRepo.fetchTransactions(from: start, to: end)
        #expect(filtered.count == 1)
    }

    @Test("Test: deleteTransaction")
    func deleteTransaction_removesTransaction() throws {
        // Objective: Ensure deleted transactions are removed from storage.
        // Given: A saved transaction ID.
        // When: deleteTransaction(id:) is called and data is fetched again.
        // Then: No transaction remains.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let account = try accountRepo.ensureDefaultPaymentMethod()

        let id = try transactionRepo.createTransaction(paymentMethodID: account, amount: 99, currency: "USD", date: Date(), merchantRaw: "Cafe", merchantNormalized: "Cafe", categoryID: nil, source: "manual", note: nil)
        try transactionRepo.deleteTransaction(id: id)

        let all = try transactionRepo.fetchTransactions()
        #expect(all.isEmpty)
    }

    @Test("Test: duplicate detection")
    func detectDuplicate_sameDayMatchingTransaction_returnsTrue() throws {
        // Objective: Detect likely duplicate transactions with matching key fields.
        // Given: A transaction already saved for the same account/day/amount/merchant.
        // When: detectDuplicate is called with identical values.
        // Then: Duplicate detection returns true.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepo = CoreDataPaymentMethodRepository(context: context)
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let account = try accountRepo.ensureDefaultPaymentMethod()

        let today = Date()
        _ = try transactionRepo.createTransaction(paymentMethodID: account, amount: 45_000, currency: "IDR", date: today, merchantRaw: "Starbucks", merchantNormalized: "Starbucks", categoryID: nil, source: "manual", note: nil)

        let isDuplicate = try transactionRepo.detectDuplicate(paymentMethodID: account, amount: 45_000, date: today, merchantNormalized: "Starbucks")
        #expect(isDuplicate)
    }
}
