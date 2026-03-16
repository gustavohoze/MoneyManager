internal import CoreData

protocol TransactionRepository {
    func fetchTransactions() throws -> [NSManagedObject]
}

protocol AccountRepository {
    func fetchAccounts() throws -> [NSManagedObject]
}

protocol MerchantRepository {
    func fetchMerchants() throws -> [NSManagedObject]
}

protocol CategoryRepository {
    func fetchCategories() throws -> [NSManagedObject]
}
