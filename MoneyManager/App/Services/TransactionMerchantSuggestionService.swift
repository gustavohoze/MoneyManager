import Foundation

/// Provides merchant name suggestions sourced directly from the Transaction store,
/// so all previously recorded merchant names are immediately available as suggestions.
struct TransactionMerchantSuggestionService: MerchantSuggestionProviding {
    private let transactionRepository: TransactionRepository

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func frequentMerchants(limit: Int) throws -> [MerchantSuggestion] {
        let names = try transactionRepository.fetchDistinctMerchantRawNames(prefix: "", limit: limit)
        return names.map { MerchantSuggestion(id: UUID(), displayName: $0, usageCount: 1, lastUsedDate: nil) }
    }

    func merchantSuggestions(for prefix: String, limit: Int) throws -> [MerchantSuggestion] {
        let names = try transactionRepository.fetchDistinctMerchantRawNames(prefix: prefix, limit: limit)
        return names.map { MerchantSuggestion(id: UUID(), displayName: $0, usageCount: 1, lastUsedDate: nil) }
    }
}
