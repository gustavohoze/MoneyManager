import Foundation
import Combine
import SwiftUI

struct SettingsToastState: Identifiable {
    let id = UUID()
    let message: String
    let isError: Bool
    let undoTitle: String?
    let undoAction: (@MainActor () -> Void)?
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var paymentMethods: [PaymentMethodListItem] = []
    @Published private(set) var categories: [TransactionFormCategoryOption] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published private(set) var toast: SettingsToastState?

    private let paymentMethodManager: PaymentMethodManaging
    private let dummyTransactionManager: DummyTransactionDataManaging
    private let optionsProvider: TransactionFormOptionsProviding

    init(
        paymentMethodManager: PaymentMethodManaging,
        dummyTransactionManager: DummyTransactionDataManaging? = nil,
        optionsProvider: TransactionFormOptionsProviding? = nil
    ) {
        self.paymentMethodManager = paymentMethodManager
        self.dummyTransactionManager = dummyTransactionManager ?? NoOpDummyTransactionDataManager()
        self.optionsProvider = optionsProvider ?? NoOpTransactionFormOptionsProvider()
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
        let previousState = paymentMethods
        do {
            try paymentMethodManager.createPaymentMethod(name: name, type: type, currency: currency)
            actionMessage = String(localized: "Payment Method created.")
            errorMessage = nil
            loadPaymentMethods()
            showToast(
                message: actionMessage ?? String(localized: "Payment Method created."),
                undoAction: { [self] in
                    restorePaymentMethods(from: previousState)
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) {
        let previousState = paymentMethods
        do {
            try paymentMethodManager.updatePaymentMethod(id: id, name: name, type: type, currency: currency)
            actionMessage = String(localized: "Payment Method updated.")
            errorMessage = nil
            loadPaymentMethods()
            showToast(
                message: actionMessage ?? String(localized: "Payment Method updated."),
                undoAction: { [self] in
                    restorePaymentMethods(from: previousState)
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func deletePaymentMethod(id: UUID) {
        let previousState = paymentMethods
        do {
            try paymentMethodManager.deletePaymentMethod(id: id)
            actionMessage = String(localized: "Payment Method deleted.")
            errorMessage = nil
            loadPaymentMethods()
            showToast(
                message: actionMessage ?? String(localized: "Payment Method deleted."),
                undoAction: { [self] in
                    restorePaymentMethods(from: previousState)
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
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
        let previousState = paymentMethods
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
            showToast(
                message: actionMessage ?? String(localized: "Display currency updated."),
                undoAction: { [self] in
                    restorePaymentMethods(from: previousState)
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func createDummyTransactions() {
        do {
            actionMessage = try dummyTransactionManager.createDummyTransactions()
            errorMessage = nil
            showToast(
                message: actionMessage ?? String(localized: "Dummy transactions created."),
                undoAction: { [self] in
                    deleteDummyTransactions()
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func deleteDummyTransactions() {
        do {
            actionMessage = try dummyTransactionManager.deleteDummyTransactions()
            errorMessage = nil
            showToast(
                message: actionMessage ?? String(localized: "Dummy transactions deleted."),
                undoAction: { [self] in
                    createDummyTransactions()
                }
            )
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func dismissToast() {
        withAnimation(.easeInOut(duration: 0.22)) {
            toast = nil
        }
    }

    func triggerToastUndo() {
        guard let undoAction = toast?.undoAction else {
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = nil
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.22)) {
            toast = nil
        }
        undoAction()
    }

    // MARK: - Layout Helpers (for Views)

    var paymentMethodsDescription: String {
        String(localized: "\(paymentMethods.count) payment methods")
    }

    var categoriesDescription: String {
        String(localized: "\(categories.count) categories")
    }

    private func showToast(message: String, isError: Bool = false, undoAction: (@MainActor () -> Void)? = nil) {
        withAnimation(.easeInOut(duration: 0.22)) {
            toast = SettingsToastState(
                message: message,
                isError: isError,
                undoTitle: undoAction == nil ? nil : String(localized: "Undo"),
                undoAction: undoAction
            )
        }
    }

    private func restorePaymentMethods(from snapshot: [PaymentMethodListItem]) {
        do {
            let current = try paymentMethodManager.loadPaymentMethods()
            let snapshotIDs = Set(snapshot.map(\.id))

            for method in current where !snapshotIDs.contains(method.id) {
                try paymentMethodManager.deletePaymentMethod(id: method.id)
            }

            let remaining = try paymentMethodManager.loadPaymentMethods()
            let remainingByID = Dictionary(uniqueKeysWithValues: remaining.map { ($0.id, $0) })

            for target in snapshot {
                if let existing = remainingByID[target.id] {
                    if existing != target {
                        try paymentMethodManager.updatePaymentMethod(
                            id: target.id,
                            name: target.name,
                            type: target.type,
                            currency: target.currency
                        )
                    }
                } else {
                    try paymentMethodManager.createPaymentMethod(
                        name: target.name,
                        type: target.type,
                        currency: target.currency
                    )
                }
            }

            loadPaymentMethods()
            showToast(message: String(localized: "Action undone."))
        } catch {
            showToast(message: error.localizedDescription, isError: true)
        }
    }
}

private struct NoOpTransactionFormOptionsProvider: TransactionFormOptionsProviding {
    func loadOptions() throws -> TransactionFormOptions {
        TransactionFormOptions(accounts: [], categories: [])
    }
}
