import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var paymentMethods: [PaymentMethodListItem] = []
    @Published private(set) var categories: [TransactionFormCategoryOption] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?

    private let paymentMethodManager: PaymentMethodManaging
    private let dummyTransactionManager: DummyTransactionDataManaging
    private let optionsProvider: TransactionFormOptionsProviding

    init(
        paymentMethodManager: PaymentMethodManaging,
        dummyTransactionManager: DummyTransactionDataManaging = NoOpDummyTransactionDataManager(),
        optionsProvider: TransactionFormOptionsProviding = NoOpTransactionFormOptionsProvider()
    ) {
        self.paymentMethodManager = paymentMethodManager
        self.dummyTransactionManager = dummyTransactionManager
        self.optionsProvider = optionsProvider
    }

    func loadSettingsData() {
        loadPaymentMethods()
        loadCategories()
    }

    func loadPaymentMethods() {
        do {
            paymentMethods = try paymentMethodManager.loadPaymentMethods()
            errorMessage = nil
        } catch {
            paymentMethods = []
            errorMessage = error.localizedDescription
        }
    }

    func loadCategories() {
        do {
            categories = try optionsProvider.loadOptions().categories
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            errorMessage = nil
        } catch {
            categories = []
            errorMessage = error.localizedDescription
        }
    }

    func createPaymentMethod(name: String, type: String, currency: String) {
        do {
            try paymentMethodManager.createPaymentMethod(name: name, type: type, currency: currency)
            actionMessage = String(localized: "Payment Method created.")
            errorMessage = nil
            loadPaymentMethods()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) {
        do {
            try paymentMethodManager.updatePaymentMethod(id: id, name: name, type: type, currency: currency)
            actionMessage = String(localized: "Payment Method updated.")
            errorMessage = nil
            loadPaymentMethods()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func deletePaymentMethod(id: UUID) {
        do {
            try paymentMethodManager.deletePaymentMethod(id: id)
            actionMessage = String(localized: "Payment Method deleted.")
            errorMessage = nil
            loadPaymentMethods()
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func savePaymentMethod(id: UUID?, name: String, type: String, currency: String) {
        if let paymentMethodID = id {
            updatePaymentMethod(id: paymentMethodID, name: name, type: type, currency: currency)
        } else {
            createPaymentMethod(name: name, type: type, currency: currency)
        }
    }

    func syncPaymentMethodsCurrency(to currencyCode: String) {
        do {
            let normalizedCurrency = AppCurrency.normalizedCode(currencyCode) ?? AppCurrency.currentCode
            for paymentMethod in paymentMethods {
                try paymentMethodManager.updatePaymentMethod(
                    id: paymentMethod.id,
                    name: paymentMethod.name,
                    type: paymentMethod.type,
                    currency: normalizedCurrency
                )
            }
            actionMessage = "All payment methods now use \(normalizedCurrency)."
            errorMessage = nil
            loadPaymentMethods()
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

private struct NoOpTransactionFormOptionsProvider: TransactionFormOptionsProviding {
    func loadOptions() throws -> TransactionFormOptions {
        TransactionFormOptions(accounts: [], categories: [])
    }
}
