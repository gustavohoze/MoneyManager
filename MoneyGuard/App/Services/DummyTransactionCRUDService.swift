import Foundation
import CoreData

protocol DummyTransactionDataManaging {
    func createDummyTransactions() throws -> String
    func deleteDummyTransactions() throws -> String
}

struct DummyTransactionCRUDService: DummyTransactionDataManaging {
    private enum Constants {
        static let marker = "DUMMY_TXN"
    }

    private let transactionRepository: TransactionRepository
    private let accountRepository: PaymentMethodRepository
    private let categoryRepository: CategoryRepository

    init(
        transactionRepository: TransactionRepository,
        accountRepository: PaymentMethodRepository,
        categoryRepository: CategoryRepository
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    func createDummyTransactions() throws -> String {
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let categoryID = try categoryRepository.upsertCategory(name: "Uncategorized", icon: "questionmark.circle", type: "expense")

        var createdCount = 0
        for index in 1...3 {
            _ = try transactionRepository.createTransaction(
                paymentMethodID: paymentMethodID,
                amount: Double(10_000 * index),
                currency: "IDR",
                date: Date(),
                merchantRaw: "Dummy Merchant \(index)",
                merchantNormalized: "Dummy Merchant \(index)",
                categoryID: categoryID,
                source: "manual",
                note: "\(Constants.marker)-\(index)"
            )
            createdCount += 1
        }

        return "Created \(createdCount) dummy transactions."
    }

    func deleteDummyTransactions() throws -> String {
        let toDelete = try fetchDummyTransactions()
            .compactMap { $0.value(forKey: "id") as? UUID }

        for id in toDelete {
            try transactionRepository.deleteTransaction(id: id)
        }

        return "Deleted \(toDelete.count) dummy transactions."
    }

    private func fetchDummyTransactions() throws -> [NSManagedObject] {
        try transactionRepository.fetchTransactions().filter { object in
            let note = (object.value(forKey: "note") as? String) ?? ""
            return note.contains(Constants.marker)
        }
    }
}

struct NoOpDummyTransactionDataManager: DummyTransactionDataManaging {
    func createDummyTransactions() throws -> String {
        "Dummy transaction create is not configured."
    }

    func deleteDummyTransactions() throws -> String {
        "Dummy transaction delete is not configured."
    }
}
