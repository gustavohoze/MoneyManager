import Foundation

protocol TransactionEntrySaving {
    func saveManualTransaction(
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String?,
        categoryID: UUID?,
        note: String?
    ) throws -> TransactionEntryResult
}

enum TransactionEntryError: LocalizedError, Equatable {
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Transaction amount must be greater than zero"
        }
    }
}

struct TransactionEntryResult {
    let transactionID: UUID
    let duplicateDetected: Bool
}

struct TransactionEntryService {
    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let merchantResolver: MerchantResolving
    private let merchantMemoryRecorder: MerchantMemoryRecording?
    private let analytics: AnalyticsTracking?

    init(
        transactionRepository: TransactionRepository,
        categoryRepository: CategoryRepository,
        merchantResolver: MerchantResolving,
        merchantMemoryRecorder: MerchantMemoryRecording? = nil,
        analytics: AnalyticsTracking? = nil
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.merchantResolver = merchantResolver
        self.merchantMemoryRecorder = merchantMemoryRecorder
        self.analytics = analytics
    }

    func saveManualTransaction(
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String?,
        categoryID: UUID?,
        note: String?
    ) throws -> TransactionEntryResult {
        guard amount > 0 else {
            throw TransactionEntryError.invalidAmount
        }

        let sanitizedMerchant = sanitizedMerchantName(merchantRaw)
        let resolvedMerchant = merchantResolver.resolve(rawMerchantName: sanitizedMerchant)
        let effectiveCategoryID = try categoryID ?? ensureUncategorizedCategory()

        let duplicateDetected = try transactionRepository.detectDuplicate(
            paymentMethodID: paymentMethodID,
            amount: amount,
            date: date,
            merchantNormalized: resolvedMerchant.normalizedName
        )

        let transactionID = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: amount,
            currency: currency,
            date: date,
            merchantRaw: sanitizedMerchant,
            merchantNormalized: resolvedMerchant.normalizedName,
            categoryID: effectiveCategoryID,
            source: "manual",
            note: note
        )

        try merchantMemoryRecorder?.recordCategoryMapping(
            merchantRaw: sanitizedMerchant,
            categoryID: effectiveCategoryID
        )

        analytics?.track(.transactionCreated)

        return TransactionEntryResult(
            transactionID: transactionID,
            duplicateDetected: duplicateDetected
        )
    }

    private func ensureUncategorizedCategory() throws -> UUID {
        try categoryRepository.upsertCategory(name: "Uncategorized", icon: "questionmark.circle", type: "expense")
    }

    private func sanitizedMerchantName(_ merchantRaw: String?) -> String {
        let trimmed = merchantRaw?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed,
           !trimmed.isEmpty {
            return trimmed
        }

        return "Unknown"
    }
}

extension TransactionEntryService: TransactionEntrySaving {}
