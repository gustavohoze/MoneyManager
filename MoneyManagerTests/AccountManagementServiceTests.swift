import Foundation
import Testing
import CoreData
@testable import MoneyManager

@MainActor
struct AccountManagementServiceTests {
    @Test("Test: create account tracks analytics")
    func createAccount_tracksAccountCreatedEvent() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let analytics = InMemoryAnalyticsService()

        let service = AccountManagementService(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository,
            analytics: analytics
        )

        try service.createAccount(name: "Travel Card", type: "credit", currency: "IDR")

        let accounts = try service.loadAccounts()
        #expect(accounts.contains { $0.name == "Travel Card" })
        #expect(analytics.allEvents().contains(.accountCreated))
    }

    @Test("Test: delete account in use is blocked")
    func deleteAccount_withTransactions_throwsAccountInUse() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let service = AccountManagementService(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        let paymentMethodID = try accountRepository.upsertPaymentMethod(name: "Wallet", type: "wallet", currency: "IDR")
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

        #expect(throws: AccountManagementError.self) {
            try service.deletePaymentMethod(id: paymentMethodID)
        }
    }

    @Test("Test: update account changes persisted values")
    func updateAccount_updatesNameTypeAndCurrency() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let service = AccountManagementService(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        let paymentMethodID = try accountRepository.upsertPaymentMethod(name: "Cash", type: "cash", currency: "IDR")

        try service.updatePaymentMethod(id: paymentMethodID, name: "Main Bank", type: "bank", currency: "usd")

        let updated = try accountRepository.fetchPaymentMethod(id: paymentMethodID)
        #expect((updated.value(forKey: "name") as? String) == "Main Bank")
        #expect((updated.value(forKey: "type") as? String) == "bank")
        #expect((updated.value(forKey: "currency") as? String) == "USD")
    }
}
