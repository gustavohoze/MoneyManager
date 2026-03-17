import Foundation
import Testing
import CoreData
@testable import MoneyManager

@MainActor
struct PaymentMethodManagementServiceTests {
    @Test("Test: create payment method tracks analytics")
    func createPaymentMethod_tracksAccountCreatedEvent() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let paymentMethodRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let analytics = InMemoryAnalyticsService()

        let service = PaymentMethodManagementService(
            paymentMethodRepository: paymentMethodRepository,
            transactionRepository: transactionRepository,
            analytics: analytics
        )

        try service.createPaymentMethod(name: "Travel Card", type: "credit", currency: "IDR")

        let paymentMethods = try service.loadPaymentMethods()
        #expect(paymentMethods.contains { $0.name == "Travel Card" })
        #expect(analytics.allEvents().contains(.accountCreated))
    }

    @Test("Test: delete payment method in use is blocked")
    func deletePaymentMethod_withTransactions_throwsPaymentMethodInUse() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let paymentMethodRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let service = PaymentMethodManagementService(
            paymentMethodRepository: paymentMethodRepository,
            transactionRepository: transactionRepository
        )

        let paymentMethodID = try paymentMethodRepository.upsertPaymentMethod(name: "Wallet", type: "wallet", currency: "IDR")
        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 50_000,
            currency: "IDR",
            date: Date(),
            merchantRaw: "Grab",
            merchantNormalized: "Grab",
            categoryID: nil,
            source: "manual",
            note: nil
        )

        #expect(throws: PaymentMethodManagementError.self) {
            try service.deletePaymentMethod(id: paymentMethodID)
        }
    }

    @Test("Test: update payment method changes persisted values")
    func updatePaymentMethod_updatesNameTypeAndCurrency() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let paymentMethodRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let service = PaymentMethodManagementService(
            paymentMethodRepository: paymentMethodRepository,
            transactionRepository: transactionRepository
        )

        let paymentMethodID = try paymentMethodRepository.upsertPaymentMethod(name: "Cash", type: "cash", currency: "IDR")

        try service.updatePaymentMethod(id: paymentMethodID, name: "Main Bank", type: "bank", currency: "usd")

        let updated = try paymentMethodRepository.fetchPaymentMethod(id: paymentMethodID)
        #expect((updated.value(forKey: "name") as? String) == "Main Bank")
        #expect((updated.value(forKey: "type") as? String) == "bank")
        #expect((updated.value(forKey: "currency") as? String) == "USD")
    }
}
