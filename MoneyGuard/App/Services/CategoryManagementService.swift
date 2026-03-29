import Foundation
import CoreData

enum CategoryManagementError: LocalizedError {
    case categoryProtected
    case categoryNotFound

    var errorDescription: String? {
        switch self {
        case .categoryProtected:
            return String(localized: "This category cannot be deleted yet")
        case .categoryNotFound:
            return String(localized: "Category not found")
        }
    }
}

protocol SettingsCategoryManaging {
    func createCategory(name: String, type: String, icon: String) throws
    func updateCategory(id: UUID, name: String, type: String, icon: String) throws
    func deleteCategory(id: UUID) throws
}

struct CategoryManagementService: SettingsCategoryManaging {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func createCategory(name: String, type: String, icon: String) throws {
        let normalizedType = normalizeType(type)
        let normalizedIcon = normalizeIcon(icon, type: normalizedType)
        _ = try categoryRepository.upsertCategory(name: name, icon: normalizedIcon, type: normalizedType)
    }

    func updateCategory(id: UUID, name: String, type: String, icon: String) throws {
        let normalizedType = normalizeType(type)
        let normalizedIcon = normalizeIcon(icon, type: normalizedType)
        try categoryRepository.updateCategory(id: id, name: name, icon: normalizedIcon, type: normalizedType)
    }

    func deleteCategory(id: UUID) throws {
        let category = try categoryRepository.fetchCategory(id: id)
        guard let categoryType = category.value(forKey: "type") as? String else {
            throw CategoryManagementError.categoryNotFound
        }

        let normalizedType = normalizeType(categoryType)
        let fallbackID = try fallbackCategoryID(forDeleting: id, type: normalizedType)
        guard fallbackID != id else {
            throw CategoryManagementError.categoryProtected
        }

        try categoryRepository.deleteCategory(id: id, remapTransactionsTo: fallbackID)
    }

    private func fallbackCategoryID(forDeleting deletingID: UUID, type: String) throws -> UUID {
        let existing = try categoryRepository.fetchCategories()
        let candidate = existing.first { category in
            guard let categoryID = category.value(forKey: "id") as? UUID,
                  let categoryType = category.value(forKey: "type") as? String
            else {
                return false
            }
            return categoryID != deletingID && normalizeType(categoryType) == type
        }

        if let candidateID = candidate?.value(forKey: "id") as? UUID {
            return candidateID
        }

        if type == "income" {
            return try categoryRepository.upsertCategory(name: "Income", icon: "arrow.down.circle.fill", type: "income")
        }

        return try categoryRepository.upsertCategory(name: "Uncategorized", icon: "questionmark.circle", type: "expense")
    }

    private func normalizeType(_ type: String) -> String {
        type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizeIcon(_ icon: String, type: String) -> String {
        let trimmed = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return Self.icon(for: type)
        }
        return trimmed
    }

    private static func icon(for type: String) -> String {
        switch type {
        case "income":
            return "arrow.down.circle.fill"
        default:
            return "questionmark.circle"
        }
    }
}
