import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var accounts: [AccountListItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    private let accountManager: AccountManaging
    private let dummyTransactionManager: DummyTransactionDataManaging

    init(
        accountManager: AccountManaging,
        dummyTransactionManager: DummyTransactionDataManaging = NoOpDummyTransactionDataManager()
    ) {
        self.accountManager = accountManager
        self.dummyTransactionManager = dummyTransactionManager
    }

    func loadAccounts() {
        do {
            accounts = try accountManager.loadAccounts()
            errorMessage = nil
        } catch {
            accounts = []
            errorMessage = error.localizedDescription
        }
    }

    func createAccount(name: String, type: String, currency: String) {
        do {
            try accountManager.createAccount(name: name, type: type, currency: currency)
            actionMessage = String(localized: "PaymentMethod created.")
            errorMessage = nil
            loadAccounts()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) {
        do {
            try accountManager.updatePaymentMethod(id: id, name: name, type: type, currency: currency)
            actionMessage = String(localized: "PaymentMethod updated.")
            errorMessage = nil
            loadAccounts()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func deletePaymentMethod(id: UUID) {
        do {
            try accountManager.deletePaymentMethod(id: id)
            actionMessage = String(localized: "PaymentMethod deleted.")
            errorMessage = nil
            loadAccounts()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func createDummyTransactions() {
        do {
            actionMessage = try dummyTransactionManager.createDummyTransactions()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func deleteDummyTransactions() {
        do {
            actionMessage = try dummyTransactionManager.deleteDummyTransactions()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }
}
