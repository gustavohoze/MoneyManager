import Foundation
import Testing
@testable import MoneyManager

private struct TransactionEntrySavingMock: TransactionEntrySaving {
    var saveHandler: (
        _ paymentMethodID: UUID,
        _ amount: Double,
        _ currency: String,
        _ date: Date,
        _ merchantRaw: String?,
        _ categoryID: UUID?,
        _ note: String?
    ) throws -> TransactionEntryResult

    func saveManualTransaction(
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String?,
        categoryID: UUID?,
        note: String?
    ) throws -> TransactionEntryResult {
        try saveHandler(paymentMethodID, amount, currency, date, merchantRaw, categoryID, note)
    }
}

private struct TransactionFormOptionsProvidingMock: TransactionFormOptionsProviding {
    var result: Result<TransactionFormOptions, Error>

    func loadOptions() throws -> TransactionFormOptions {
        try result.get()
    }
}

@MainActor
struct AddTransactionViewModelTests {
    @Test("Test: missing account prevents save")
    func save_withoutSelectedAccount_setsMissingAccountError() {
        // Objective: Keep required account field enforced before calling service.
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: UUID(), duplicateDetected: false)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(TransactionFormOptions(accounts: [], categories: []))
            )
        )

        viewModel.amountText = "12000"
        viewModel.save()

        #expect(viewModel.error == .missingAccount)
        #expect(viewModel.lastSavedTransactionID == nil)
    }

    @Test("Test: invalid amount prevents save")
    func save_invalidAmount_setsInvalidAmountError() {
        // Objective: Reject malformed or non-positive amount text in ViewModel.
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: UUID(), duplicateDetected: false)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(TransactionFormOptions(accounts: [], categories: []))
            )
        )

        viewModel.selectedAccountID = UUID()
        viewModel.amountText = "abc"
        viewModel.save()

        #expect(viewModel.error == .invalidAmount)
        #expect(viewModel.lastSavedTransactionID == nil)
    }

    @Test("Test: successful save updates state")
    func save_success_setsSavedTransactionAndDuplicateWarning() {
        // Objective: Reflect service output back into UI state.
        let expectedID = UUID()
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: expectedID, duplicateDetected: true)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(TransactionFormOptions(accounts: [], categories: []))
            )
        )

        viewModel.selectedAccountID = UUID()
        viewModel.amountText = "9000"
        viewModel.merchantRaw = "Grab"
        viewModel.note = "   "

        viewModel.save()

        #expect(viewModel.error == nil)
        #expect(viewModel.lastSavedTransactionID == expectedID)
        #expect(viewModel.duplicateWarning == true)
        #expect(viewModel.isSaving == false)
    }

    @Test("Test: service validation maps to viewmodel error")
    func save_serviceThrowsInvalidAmount_mapsToInvalidAmount() {
        // Objective: Keep consistent validation messaging if service rejects amount.
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                throw TransactionEntryError.invalidAmount
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(TransactionFormOptions(accounts: [], categories: []))
            )
        )

        viewModel.selectedAccountID = UUID()
        viewModel.amountText = "500"
        viewModel.save()

        #expect(viewModel.error == .invalidAmount)
        #expect(viewModel.lastSavedTransactionID == nil)
    }

    @Test("Test: options loading sets defaults")
    func loadOptions_withData_setsAccountCategoryAndDefaults() {
        // Objective: Ensure Add Transaction form can initialize selections from repository-backed options.
        let paymentMethodID = UUID()
        let categoryID = UUID()
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: UUID(), duplicateDetected: false)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(
                    TransactionFormOptions(
                        accounts: [TransactionFormAccountOption(id: paymentMethodID, name: "Cash")],
                        categories: [TransactionFormCategoryOption(id: categoryID, name: "Uncategorized")]
                    )
                )
            )
        )

        viewModel.loadOptions()

        #expect(viewModel.accountOptions.count == 1)
        #expect(viewModel.categoryOptions.count == 1)
        #expect(viewModel.selectedAccountID == paymentMethodID)
        #expect(viewModel.selectedCategoryID == categoryID)
    }
}
