import Foundation
import CoreData

struct TransactionListItem: Equatable {
    let id: UUID
    let merchant: String
    let amount: Double
    let category: String
    let account: String
    let date: Date
}

struct TransactionListSection: Equatable {
    let title: String
    let items: [TransactionListItem]
}

protocol TransactionListDataProviding {
    func loadSections(asOf date: Date) throws -> [TransactionListSection]
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

    func loadSections(asOf date: Date = Date()) throws -> [TransactionListSection] {
        let transactions = try transactionRepository.fetchTransactions()
        let categories = try categoryRepository.fetchCategories()
        let accounts = try accountRepository.fetchPaymentMethods()

        let categoryByID = categories.reduce(into: [UUID: String]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String
            else {
                return
            }
            partialResult[id] = name
        }

        let accountByID = accounts.reduce(into: [UUID: String]()) { partialResult, object in
            guard
                let id = object.value(forKey: "id") as? UUID,
                let name = object.value(forKey: "name") as? String
            else {
                return
            }
            partialResult[id] = name
        }

        var todayItems: [TransactionListItem] = []
        var yesterdayItems: [TransactionListItem] = []
        var earlierItems: [TransactionListItem] = []

        let calendar = Calendar(identifier: .iso8601)

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
            let categoryName = categoryID.flatMap { categoryByID[$0] } ?? "Uncategorized"

            let paymentMethodID = object.value(forKey: "paymentMethodID") as? UUID
            let accountName = paymentMethodID.flatMap { accountByID[$0] } ?? "Unknown"

            let item = TransactionListItem(
                id: id,
                merchant: merchant,
                amount: amount,
                category: categoryName,
                account: accountName,
                date: transactionDate
            )

            if calendar.isDate(transactionDate, inSameDayAs: date) {
                todayItems.append(item)
            } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: date), calendar.isDate(transactionDate, inSameDayAs: yesterday) {
                yesterdayItems.append(item)
            } else {
                earlierItems.append(item)
            }
        }

        var sections: [TransactionListSection] = []
        if !todayItems.isEmpty {
            sections.append(TransactionListSection(title: "Today", items: todayItems))
        }
        if !yesterdayItems.isEmpty {
            sections.append(TransactionListSection(title: "Yesterday", items: yesterdayItems))
        }
        if !earlierItems.isEmpty {
            sections.append(TransactionListSection(title: "Earlier", items: earlierItems))
        }

        return sections
    }
}
