import Foundation
import CoreData

struct TransactionListItem: Equatable {
    let id: UUID
    let merchant: String
    let amount: Double
    let categoryType: String
    let category: String
    let categoryIcon: String
    let account: String
    let date: Date
}

struct TransactionListSection: Equatable {
    let title: String
    let items: [TransactionListItem]
}

protocol TransactionListDataProviding {
    func loadItems() throws -> [TransactionListItem]
}

struct TransactionListDataService: TransactionListDataProviding {
    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository
    private let accountRepository: PaymentMethodRepository

    init(
        transactionRepository: TransactionRepository,
        categoryRepository: CategoryRepository,
        accountRepository: PaymentMethodRepository
    ) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        self.accountRepository = accountRepository
    }

    func loadItems() throws -> [TransactionListItem] {
        let transactions = try transactionRepository.fetchTransactions()
        let categories = try categoryRepository.fetchCategories()
        let paymentMethods = try accountRepository.fetchPaymentMethods()

        let categoryByID = categories.reduce(into: [UUID: (name: String, icon: String, type: String)]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String
            else {
                return
            }
            let icon = (object.value(forKey: "icon") as? String) ?? "questionmark.circle"
            let type = (object.value(forKey: "type") as? String) ?? "expense"
            partialResult[id] = (name: name, icon: icon, type: type)
        }

        let paymentMethodByID = paymentMethods.reduce(into: [UUID: String]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String
            else {
                return
            }
            partialResult[id] = name
        }

        var items: [TransactionListItem] = []

        for object in transactions {
            guard let id = object.value(forKey: "id") as? UUID else {
                continue
            }

            let transactionDate = (object.value(forKey: "date") as? Date) ?? .distantPast
            let normalized = (object.value(forKey: "merchantNormalized") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let raw = (object.value(forKey: "merchantRaw") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let merchant = !normalized.isEmpty ? normalized : (!raw.isEmpty ? raw : "Unknown")
            let amount = (object.value(forKey: "amount") as? Double) ?? 0

            let categoryID = object.value(forKey: "categoryID") as? UUID
            let categoryDetails = categoryID.flatMap { categoryByID[$0] }
            let categoryName = categoryDetails?.name ?? "Uncategorized"
            let categoryIcon = categoryDetails?.icon ?? "questionmark.circle"
            let categoryType = categoryDetails?.type ?? "expense"

            let paymentMethodID = object.value(forKey: "paymentMethodID") as? UUID
            let paymentMethodName = paymentMethodID.flatMap { paymentMethodByID[$0] } ?? "Unknown"

            let item = TransactionListItem(
                id: id,
                merchant: merchant,
                amount: amount,
                categoryType: categoryType,
                category: categoryName,
                categoryIcon: categoryIcon,
                account: paymentMethodName,
                date: transactionDate
            )

            items.append(item)
        }

        return items.sorted { lhs, rhs in
            lhs.date > rhs.date
        }
    }
}
