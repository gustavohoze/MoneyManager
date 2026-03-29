import Foundation
import Combine
import SwiftUI
import CoreData

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
    private let categoryManager: SettingsCategoryManaging
    private let dummyTransactionManager: DummyTransactionDataManaging
    private let optionsProvider: TransactionFormOptionsProviding
    private let exportService: ExportService?
    private let importService: ImportService?

    init(
        paymentMethodManager: PaymentMethodManaging,
        categoryManager: SettingsCategoryManaging? = nil,
        dummyTransactionManager: DummyTransactionDataManaging? = nil,
        optionsProvider: TransactionFormOptionsProviding? = nil,
        exportService: ExportService? = nil,
        importService: ImportService? = nil
    ) {
        self.paymentMethodManager = paymentMethodManager
        self.categoryManager = categoryManager ?? NoOpSettingsCategoryManager()
        self.dummyTransactionManager = dummyTransactionManager ?? NoOpDummyTransactionDataManager()
        self.optionsProvider = optionsProvider ?? NoOpTransactionFormOptionsProvider()
        self.exportService = exportService
        self.importService = importService
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

    func createCategory(name: String, type: String, icon: String) {
        do {
            try categoryManager.createCategory(name: name, type: type, icon: icon)
            actionMessage = String(localized: "Category created.")
            errorMessage = nil
            loadCategories()
            showToast(message: actionMessage ?? String(localized: "Category created."))
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func updateCategory(id: UUID, name: String, type: String, icon: String) {
        do {
            try categoryManager.updateCategory(id: id, name: name, type: type, icon: icon)
            actionMessage = String(localized: "Category updated.")
            errorMessage = nil
            loadCategories()
            showToast(message: actionMessage ?? String(localized: "Category updated."))
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func deleteCategory(id: UUID) {
        do {
            try categoryManager.deleteCategory(id: id)
            actionMessage = String(localized: "Category deleted.")
            errorMessage = nil
            loadCategories()
            showToast(message: actionMessage ?? String(localized: "Category deleted."))
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
            showToast(message: error.localizedDescription, isError: true)
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

    func exportTransactionsAsJSON() -> Data? {
        guard let exportService = exportService else {
            showToast(message: String(localized: "Export service not available."), isError: true)
            return nil
        }

        do {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
            fetchRequest.returnsObjectsAsFaults = false
            let transactions = try context.fetch(fetchRequest)

            let jsonString = exportService.makeJSON(from: transactions)
            guard let data = jsonString.data(using: .utf8) else { return nil }
            return data
        } catch {
            showToast(message: error.localizedDescription, isError: true)
            return nil
        }
    }

    func exportTransactionsAsCSV() -> Data? {
        guard let exportService = exportService else {
            showToast(message: String(localized: "Export service not available."), isError: true)
            return nil
        }

        do {
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
            fetchRequest.returnsObjectsAsFaults = false
            let transactions = try context.fetch(fetchRequest)

            let csvString = exportService.makeCSV(from: transactions)
            guard let data = csvString.data(using: .utf8) else { return nil }
            return data
        } catch {
            showToast(message: error.localizedDescription, isError: true)
            return nil
        }
    }

    func importTransactions(from data: Data, format: String) {
        guard let importService = importService else {
            showToast(message: String(localized: "Import service not available."), isError: true)
            return
        }

        do {
            let result: (transactionsImported: Int, categoriesImported: Int)

            if format.lowercased() == "json" {
                result = try importService.importFromJSON(data)
            } else if format.lowercased() == "csv" {
                result = try importService.importFromCSV(data)
            } else {
                showToast(message: String(localized: "Unsupported file format."), isError: true)
                return
            }

            let message = String(
                localized: "\(result.transactionsImported) transactions and \(result.categoriesImported) categories imported."
            )
            showToast(message: message)
            loadCategories()
        } catch {
            showToast(message: error.localizedDescription, isError: true)
        }
    }

    func presentToast(message: String, isError: Bool = false) {
        showToast(message: message, isError: isError)
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

private struct NoOpSettingsCategoryManager: SettingsCategoryManaging {
    func createCategory(name: String, type: String, icon: String) throws {}

    func updateCategory(id: UUID, name: String, type: String, icon: String) throws {}

    func deleteCategory(id: UUID) throws {}
}
