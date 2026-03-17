import CoreData

protocol TransactionRepository {
    @discardableResult
    func createExampleTransaction(paymentMethodID: UUID) throws -> UUID
    @discardableResult
    func createTransaction(
        paymentMethodID: UUID,
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
    func fetchRecentTransactions(limit: Int) throws -> [NSManagedObject]
    func fetchTransaction(id: UUID) throws -> NSManagedObject
    func fetchTransactions(paymentMethodID: UUID) throws -> [NSManagedObject]
    func fetchTransactions(from startDate: Date, to endDate: Date) throws -> [NSManagedObject]
    func fetchTransactions(from startDate: Date, to endDate: Date, limit: Int?) throws -> [NSManagedObject]
    func updateTransaction(
        id: UUID,
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String,
        merchantNormalized: String?,
        categoryID: UUID?,
        note: String?
    ) throws
    func deleteTransaction(id: UUID) throws
    func detectDuplicate(
        paymentMethodID: UUID,
        amount: Double,
        date: Date,
        merchantNormalized: String?
    ) throws -> Bool
    func fetchDistinctMerchantRawNames(prefix: String, limit: Int) throws -> [String]
}

extension TransactionRepository {
    func fetchRecentTransactions(limit: Int) throws -> [NSManagedObject] {
        let normalizedLimit = max(1, limit)
        return Array(try fetchTransactions().prefix(normalizedLimit))
    }

    func fetchTransactions(from startDate: Date, to endDate: Date, limit: Int? = nil) throws -> [NSManagedObject] {
        let values = try fetchTransactions(from: startDate, to: endDate)
        guard let limit else {
            return values
        }
        return Array(values.prefix(max(0, limit)))
    }
}

protocol PaymentMethodRepository {
    @discardableResult
    func ensureDefaultPaymentMethod() throws -> UUID
    @discardableResult
    func upsertPaymentMethod(name: String, type: String, currency: String) throws -> UUID
    func fetchPaymentMethod(id: UUID) throws -> NSManagedObject
    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws
    func deletePaymentMethod(id: UUID) throws
    func fetchPaymentMethods() throws -> [NSManagedObject]
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
