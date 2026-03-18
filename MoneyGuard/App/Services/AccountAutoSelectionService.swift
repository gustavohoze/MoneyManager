import Foundation
import CoreData

protocol AccountAutoSelectionProviding {
    func lastUsedAccountID() throws -> UUID?
    func recordAccountUsage(paymentMethodID: UUID) throws
}

struct AccountAutoSelectionService: AccountAutoSelectionProviding {
    private static let lastUsedAccountIDKey = "settings.lastUsedAccountID"

    private let accountRepository: PaymentMethodRepository
    private let transactionRepository: TransactionRepository
    private let defaults: UserDefaults

    init(
        accountRepository: PaymentMethodRepository,
        transactionRepository: TransactionRepository,
        defaults: UserDefaults = .standard
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
        self.defaults = defaults
    }

    func lastUsedAccountID() throws -> UUID? {
        if let rawID = defaults.string(forKey: Self.lastUsedAccountIDKey),
           let storedID = UUID(uuidString: rawID),
           (try? accountRepository.fetchPaymentMethod(id: storedID)) != nil {
            return storedID
        }

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

        defaults.set(paymentMethodID.uuidString, forKey: Self.lastUsedAccountIDKey)
        return paymentMethodID
    }

    func recordAccountUsage(paymentMethodID: UUID) throws {
        guard (try? accountRepository.fetchPaymentMethod(id: paymentMethodID)) != nil else {
            return
        }

        defaults.set(paymentMethodID.uuidString, forKey: Self.lastUsedAccountIDKey)
    }
}
