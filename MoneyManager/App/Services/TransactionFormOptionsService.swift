import Foundation
import CoreData

struct TransactionFormAccountOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    var icon: String = "creditcard"
}

struct TransactionFormCategoryOption: Identifiable, Equatable {
    let id: UUID
    let name: String
    var icon: String = "questionmark.circle"
}

struct TransactionFormOptions: Equatable {
    let accounts: [TransactionFormAccountOption]
    let categories: [TransactionFormCategoryOption]
}

protocol TransactionFormOptionsProviding {
    func loadOptions() throws -> TransactionFormOptions
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
                return TransactionFormAccountOption(id: id, name: name, icon: Self.icon(forPaymentMethodType: type))
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
                return TransactionFormCategoryOption(id: id, name: name, icon: icon)
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
