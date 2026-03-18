import Foundation
import CoreData

struct PaymentMethodListItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: String
    let currency: String
}

protocol PaymentMethodManaging {
    func loadPaymentMethods() throws -> [PaymentMethodListItem]
    func createPaymentMethod(name: String, type: String, currency: String) throws
    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws
    func deletePaymentMethod(id: UUID) throws
}

struct PaymentMethodManagementService: PaymentMethodManaging {
    private let paymentMethodRepository: PaymentMethodRepository
    private let transactionRepository: TransactionRepository
    private let analytics: AnalyticsTracking?

    init(
        paymentMethodRepository: PaymentMethodRepository,
        transactionRepository: TransactionRepository,
        analytics: AnalyticsTracking? = nil
    ) {
        self.paymentMethodRepository = paymentMethodRepository
        self.transactionRepository = transactionRepository
        self.analytics = analytics
    }

    func loadPaymentMethods() throws -> [PaymentMethodListItem] {
        try paymentMethodRepository.fetchPaymentMethods()
            .compactMap { object in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let name = object.value(forKey: "name") as? String,
                    let type = object.value(forKey: "type") as? String,
                    let currency = object.value(forKey: "currency") as? String
                else {
                    return nil
                }

                return PaymentMethodListItem(id: id, name: name, type: type, currency: currency)
            }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func createPaymentMethod(name: String, type: String, currency: String) throws {
        let normalizedCurrency = AppCurrency.normalizedCode(currency) ?? AppCurrency.currentCode
        _ = try paymentMethodRepository.upsertPaymentMethod(name: name, type: type, currency: normalizedCurrency)
        analytics?.track(.accountCreated)
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws {
        let normalizedCurrency = AppCurrency.normalizedCode(currency) ?? AppCurrency.currentCode
        try paymentMethodRepository.updatePaymentMethod(id: id, name: name, type: type, currency: normalizedCurrency)
    }

    func deletePaymentMethod(id: UUID) throws {
        let hasTransactions = try !transactionRepository.fetchTransactions(paymentMethodID: id).isEmpty
        if hasTransactions {
            throw PaymentMethodManagementError.paymentMethodInUse
        }

        try paymentMethodRepository.deletePaymentMethod(id: id)
    }
}
