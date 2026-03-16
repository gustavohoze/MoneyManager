import CoreData

protocol TransactionRepository {
    @discardableResult
    func createExampleTransaction(accountID: UUID) throws -> UUID
    @discardableResult
    func createTransaction(
        accountID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String,
        merchantNormalized: String?,
        categoryID: UUID?,
        source: String,
        note: String?
    ) throws -> UUID
    func fetchTransactions() throws -> [NSManagedObject]
    func fetchTransactions(accountID: UUID) throws -> [NSManagedObject]
    func fetchTransactions(from startDate: Date, to endDate: Date) throws -> [NSManagedObject]
    func deleteTransaction(id: UUID) throws
    func detectDuplicate(
        accountID: UUID,
        amount: Double,
        date: Date,
        merchantNormalized: String?
    ) throws -> Bool
}

protocol AccountRepository {
    @discardableResult
    func ensureDefaultAccount() throws -> UUID
    @discardableResult
    func upsertAccount(name: String, type: String, currency: String) throws -> UUID
    func fetchAccounts() throws -> [NSManagedObject]
}

protocol MerchantRepository {
    @discardableResult
    func upsertSampleMerchant(rawName: String) throws -> UUID
    @discardableResult
    func upsertMerchant(
        rawName: String,
        normalizedName: String,
        brand: String?,
        category: String?,
        confidence: Double
    ) throws -> UUID
    func fetchMerchants() throws -> [NSManagedObject]
}

protocol CategoryRepository {
    @discardableResult
    func seedInitialCategories() throws -> Int
    @discardableResult
    func upsertCategory(name: String, icon: String, type: String) throws -> UUID
    func fetchCategories() throws -> [NSManagedObject]
}
