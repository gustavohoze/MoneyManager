import Foundation

extension AddTransactionViewModel {
    static var previewInstance: AddTransactionViewModel {
        AddTransactionViewModel(
            transactionEntryService: PreviewTransactionEntrySaving(),
            optionsProvider: PreviewTransactionFormOptionsProviding()
        )
    }
}

struct PreviewTransactionEntrySaving: TransactionEntrySaving {
    func saveManualTransaction(
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String?,
        categoryID: UUID?,
        note: String?
    ) throws -> TransactionEntryResult {
        TransactionEntryResult(transactionID: UUID(), duplicateDetected: false)
    }
}

struct PreviewTransactionFormOptionsProviding: TransactionFormOptionsProviding {
    func loadOptions() throws -> TransactionFormOptions {
        TransactionFormOptions(
            accounts: [
                TransactionFormAccountOption(id: UUID(), name: "Cash"),
                TransactionFormAccountOption(id: UUID(), name: "Bank")
            ],
            categories: [
                TransactionFormCategoryOption(id: UUID(), name: "Food"),
                TransactionFormCategoryOption(id: UUID(), name: "Transport"),
                TransactionFormCategoryOption(id: UUID(), name: "Shopping")
            ]
        )
    }
}
