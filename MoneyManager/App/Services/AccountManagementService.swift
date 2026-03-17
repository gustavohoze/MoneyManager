import Foundation
import CoreData

struct AccountListItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: String
    let currency: String
}

enum AccountManagementError: LocalizedError, Equatable {
    case accountInUse

    var errorDescription: String? {
        switch self {
        case .accountInUse:
            return "This account is used by transactions and cannot be deleted"
        }
    }
}

protocol AccountManaging {
    func loadAccounts() throws -> [AccountListItem]
    func createAccount(name: String, type: String, currency: String) throws
    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws
    func deletePaymentMethod(id: UUID) throws
}

struct AccountManagementService: AccountManaging {
    private let accountRepository: PaymentMethodRepository
    private let transactionRepository: TransactionRepository
    private let analytics: AnalyticsTracking?

    init(
        accountRepository: PaymentMethodRepository,
        transactionRepository: TransactionRepository,
        analytics: AnalyticsTracking? = nil
    ) {
        self.accountRepository = accountRepository
        self.transactionRepository = transactionRepository
        self.analytics = analytics
    }

    func loadAccounts() throws -> [AccountListItem] {
        try accountRepository.fetchPaymentMethods()
            .compactMap { object in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let name = object.value(forKey: "name") as? String,
                    let type = object.value(forKey: "type") as? String,
                    let currency = object.value(forKey: "currency") as? String
                else {
                    return nil
                }

                return AccountListItem(id: id, name: name, type: type, currency: currency)
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func createAccount(name: String, type: String, currency: String) throws {
        _ = try accountRepository.upsertPaymentMethod(name: name, type: type, currency: currency)
        analytics?.track(.accountCreated)
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws {
        try accountRepository.updatePaymentMethod(id: id, name: name, type: type, currency: currency)
    }

    func deletePaymentMethod(id: UUID) throws {
        let hasTransactions = try !transactionRepository.fetchTransactions(paymentMethodID: id).isEmpty
        if hasTransactions {
            throw AccountManagementError.accountInUse
        }

        try accountRepository.deletePaymentMethod(id: id)
    }
}
