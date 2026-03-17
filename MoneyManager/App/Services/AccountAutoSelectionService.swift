import Foundation
import CoreData

protocol AccountAutoSelectionProviding {
    func lastUsedAccountID() throws -> UUID?
    func recordAccountUsage(paymentMethodID: UUID) throws
}

struct AccountAutoSelectionService: AccountAutoSelectionProviding {
    private let accountRepository: PaymentMethodRepository
    private let transactionRepository: TransactionRepository

    init(
        accountRepository: PaymentMethodRepository,
        transactionRepository: TransactionRepository
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
    }

    func lastUsedAccountID() throws -> UUID? {
        let allTransactions = try transactionRepository.fetchTransactions()
        guard let mostRecent = (allTransactions.max { trans1, trans2 in
            let date1 = (trans1.value(forKey: "date") as? Date) ?? Date.distantPast
            let date2 = (trans2.value(forKey: "date") as? Date) ?? Date.distantPast
            return date1.compare(date2) == .orderedAscending
        }),
        let paymentMethodID = mostRecent.value(forKey: "paymentMethodID") as? UUID
        else {
            return nil
        }
        return paymentMethodID
    }

    func recordAccountUsage(paymentMethodID: UUID) throws {
        // This is called when saving a transaction, updates account's lastUsedDate
        // Future implementation: add lastUsedDate field to PaymentMethod entity and update it here
    }
}
