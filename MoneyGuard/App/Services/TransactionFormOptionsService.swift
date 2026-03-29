import Foundation
import CoreData

struct TransactionFormAccountOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    var icon: String = "creditcard"
    var currency: String = "IDR"
}

struct TransactionFormCategoryOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    var icon: String = "questionmark.circle"
    var type: String = "expense"
}

struct TransactionFormOptions: Equatable {
    let accounts: [TransactionFormAccountOption]
    let categories: [TransactionFormCategoryOption]
}

protocol TransactionFormOptionsProviding {
    func loadOptions() throws -> TransactionFormOptions
}

protocol TransactionCategoryManaging {
    func upsertCategory(name: String, type: String) throws -> TransactionFormCategoryOption
}

struct TransactionFormOptionsService: TransactionFormOptionsProviding {
    private let accountRepository: PaymentMethodRepository
    private let categoryRepository: CategoryRepository

    init(accountRepository: PaymentMethodRepository, categoryRepository: CategoryRepository) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    func loadOptions() throws -> TransactionFormOptions {
        let accounts = try accountRepository.fetchPaymentMethods()
            .compactMap { object -> TransactionFormAccountOption? in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let name = object.value(forKey: "name") as? String
                else {
                    return nil
                }
                let type = object.value(forKey: "type") as? String ?? "cash"
                let currency = (object.value(forKey: "currency") as? String) ?? "IDR"
                return TransactionFormAccountOption(
                    id: id,
                    name: name,
                    icon: Self.icon(forPaymentMethodType: type),
                    currency: currency
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let categories = try categoryRepository.fetchCategories()
            .compactMap { object -> TransactionFormCategoryOption? in
                guard
                    let id = object.value(forKey: "id") as? UUID,
                    let name = object.value(forKey: "name") as? String
                else {
                    return nil
                }
                let icon = object.value(forKey: "icon") as? String ?? "questionmark.circle"
                let type = object.value(forKey: "type") as? String ?? "expense"
                return TransactionFormCategoryOption(id: id, name: name, icon: icon, type: type)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        return TransactionFormOptions(accounts: accounts, categories: categories)
    }

    private static func icon(forPaymentMethodType type: String) -> String {
        switch type.lowercased() {
        case "cash": return "banknote"
        case "credit", "credit_card", "creditcard": return "creditcard"
        case "debit", "debit_card": return "creditcard.fill"
        case "bank", "checking", "savings", "saving": return "building.columns"
        default: return "creditcard"
        }
    }
}

struct TransactionCategoryService: TransactionCategoryManaging {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func upsertCategory(name: String, type: String) throws -> TransactionFormCategoryOption {
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let icon = Self.defaultIcon(for: normalizedType)
        let id = try categoryRepository.upsertCategory(name: name, icon: icon, type: normalizedType)
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        return TransactionFormCategoryOption(
            id: id,
            name: normalizedName,
            icon: icon,
            type: normalizedType
        )
    }

    private static func defaultIcon(for type: String) -> String {
        switch type {
        case "income":
            return "arrow.down.circle.fill"
        default:
            return "questionmark.circle"
        }
    }
}
