import Foundation
import CoreData

struct MerchantSuggestion: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let usageCount: Int
    let lastUsedDate: Date?
}

protocol MerchantMemoryRecording {
    func recordCategoryMapping(merchantRaw: String, categoryID: UUID?) throws
    func recordMerchantUsage(merchantRaw: String) throws
}

protocol MerchantCategorySuggesting {
    func suggestedCategoryID(for merchantRaw: String) throws -> UUID?
}

protocol MerchantSuggestionProviding {
    func frequentMerchants(limit: Int) throws -> [MerchantSuggestion]
    func merchantSuggestions(for prefix: String, limit: Int) throws -> [MerchantSuggestion]
}

struct MerchantMemoryService: MerchantMemoryRecording, MerchantCategorySuggesting, MerchantSuggestionProviding {
    private let merchantRepository: MerchantRepository
    private let categoryRepository: CategoryRepository
    private let merchantResolver: MerchantResolving

    init(
        merchantRepository: MerchantRepository,
        categoryRepository: CategoryRepository,
        merchantResolver: MerchantResolving
    ) {
        self.merchantRepository = merchantRepository
        self.categoryRepository = categoryRepository
        self.merchantResolver = merchantResolver
    }

    func recordCategoryMapping(merchantRaw: String, categoryID: UUID?) throws {
        let trimmedMerchant = merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            return
        }

        let categoryName = try categoryName(for: categoryID)
        let resolved = merchantResolver.resolve(rawMerchantName: trimmedMerchant)

        _ = try merchantRepository.upsertMerchant(
            rawName: trimmedMerchant,
            normalizedName: resolved.normalizedName,
            brand: resolved.normalizedName,
            category: categoryName,
            confidence: resolved.confidence
        )
    }

    func recordMerchantUsage(merchantRaw: String) throws {
        let trimmedMerchant = merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            return
        }

        let resolved = merchantResolver.resolve(rawMerchantName: trimmedMerchant)
        _ = try merchantRepository.upsertMerchant(
            rawName: trimmedMerchant,
            normalizedName: resolved.normalizedName,
            brand: resolved.normalizedName,
            category: nil,
            confidence: resolved.confidence
        )
    }

    func suggestedCategoryID(for merchantRaw: String) throws -> UUID? {
        let trimmedMerchant = merchantRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            return nil
        }

        let normalizedName = merchantResolver.resolve(rawMerchantName: trimmedMerchant).normalizedName
        let merchants = try merchantRepository.fetchMerchants()

        guard let categoryName = merchants.first(where: { merchant in
            let storedNormalized = (merchant.value(forKey: "normalizedName") as? String) ?? ""
            return storedNormalized.compare(normalizedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        })?.value(forKey: "category") as? String else {
            return nil
        }

        let categories = try categoryRepository.fetchCategories()
        return categories.first(where: { category in
            let name = (category.value(forKey: "name") as? String) ?? ""
            return name.compare(categoryName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        })?.value(forKey: "id") as? UUID
    }

    func frequentMerchants(limit: Int) throws -> [MerchantSuggestion] {
        let merchants = try merchantRepository.fetchMerchants()
        let suggestions = merchants.compactMap { merchant -> MerchantSuggestion? in
            guard
                let id = merchant.value(forKey: "id") as? UUID,
                let rawName = merchant.value(forKey: "rawName") as? String
            else {
                return nil
            }
            let usageCount = ((merchant.value(forKey: "usageCount") as? NSNumber)?.intValue)
                ?? (merchant.value(forKey: "usageCount") as? Int)
                ?? 0
            let lastUsedDate = merchant.value(forKey: "lastUsedDate") as? Date
            return MerchantSuggestion(id: id, displayName: rawName, usageCount: usageCount, lastUsedDate: lastUsedDate)
        }
        return Array(suggestions.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
    }

    func merchantSuggestions(for prefix: String, limit: Int) throws -> [MerchantSuggestion] {
        guard !prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return try frequentMerchants(limit: limit)
        }

        let merchants = try merchantRepository.fetchMerchants()
        let prefixLower = prefix.lowercased()

        let suggestions = merchants.compactMap { merchant -> MerchantSuggestion? in
            guard
                let id = merchant.value(forKey: "id") as? UUID,
                let rawName = merchant.value(forKey: "rawName") as? String,
                rawName.lowercased().hasPrefix(prefixLower)
            else {
                return nil
            }
            let usageCount = ((merchant.value(forKey: "usageCount") as? NSNumber)?.intValue)
                ?? (merchant.value(forKey: "usageCount") as? Int)
                ?? 0
            let lastUsedDate = merchant.value(forKey: "lastUsedDate") as? Date
            return MerchantSuggestion(id: id, displayName: rawName, usageCount: usageCount, lastUsedDate: lastUsedDate)
        }

        return Array(suggestions.sorted { $0.usageCount > $1.usageCount }.prefix(limit))
    }

    private func categoryName(for categoryID: UUID?) throws -> String? {
        guard let categoryID else {
            return nil
        }

        let categories = try categoryRepository.fetchCategories()
        return categories.first(where: { ($0.value(forKey: "id") as? UUID) == categoryID })?.value(forKey: "name") as? String
    }
}
