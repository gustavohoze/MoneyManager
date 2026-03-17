import Foundation
import CoreData

struct TransactionEditDraft: Equatable {
    let id: UUID
    var paymentMethodID: UUID
    var amount: Double
    var currency: String
    var date: Date
    var merchantRaw: String
    var categoryID: UUID?
    var note: String?
}

protocol TransactionMutating {
    func loadEditDraft(id: UUID) throws -> TransactionEditDraft
    func updateTransaction(draft: TransactionEditDraft) throws
    func deleteTransaction(id: UUID) throws
}

struct TransactionMutationService: TransactionMutating {
    private let transactionRepository: TransactionRepository
    private let merchantResolver: MerchantResolving
    private let analytics: AnalyticsTracking?

    init(
        transactionRepository: TransactionRepository,
        merchantResolver: MerchantResolving,
        analytics: AnalyticsTracking? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.merchantResolver = merchantResolver
        self.analytics = analytics
    }

    func loadEditDraft(id: UUID) throws -> TransactionEditDraft {
        let object = try transactionRepository.fetchTransaction(id: id)

        guard
            let paymentMethodID = object.value(forKey: "paymentMethodID") as? UUID,
            let amount = object.value(forKey: "amount") as? Double,
            let currency = object.value(forKey: "currency") as? String,
            let date = object.value(forKey: "date") as? Date
        else {
            throw CoreDataRepositoryError.invalidValue(field: "transaction", value: id.uuidString)
        }

        let merchantRaw = (object.value(forKey: "merchantRaw") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let note = object.value(forKey: "note") as? String
        let categoryID = object.value(forKey: "categoryID") as? UUID

        return TransactionEditDraft(
            id: id,
            paymentMethodID: paymentMethodID,
            amount: amount,
            currency: currency,
            date: date,
            merchantRaw: merchantRaw,
            categoryID: categoryID,
            note: note
        )
    }

    func updateTransaction(draft: TransactionEditDraft) throws {
        let sanitizedMerchant = draft.merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let merchantToPersist = sanitizedMerchant.isEmpty ? "Unknown" : sanitizedMerchant
        let normalizedMerchant = merchantResolver.resolve(rawMerchantName: merchantToPersist).normalizedName

        try transactionRepository.updateTransaction(
            id: draft.id,
            paymentMethodID: draft.paymentMethodID,
            amount: draft.amount,
            currency: draft.currency,
            date: draft.date,
            merchantRaw: merchantToPersist,
            merchantNormalized: normalizedMerchant,
            categoryID: draft.categoryID,
            note: draft.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true ? nil : draft.note
        )

        analytics?.track(.transactionEdited)
    }

    func deleteTransaction(id: UUID) throws {
        try transactionRepository.deleteTransaction(id: id)
        analytics?.track(.transactionDeleted)
    }
}

struct NoOpTransactionMutationService: TransactionMutating {
    func loadEditDraft(id: UUID) throws -> TransactionEditDraft {
        throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: id)
    }

    func updateTransaction(draft: TransactionEditDraft) throws {
        // Intentionally no-op for tests/previews that only need list loading.
    }

    func deleteTransaction(id: UUID) throws {
        // Intentionally no-op for tests/previews that only need list loading.
    }
}
