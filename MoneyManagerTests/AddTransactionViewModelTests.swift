import Foundation
import Testing
@testable import Money_Guard

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

private struct TransactionMutatingMock: TransactionMutating {
    var deleteHandler: (UUID) throws -> Void = { _ in }

    func loadEditDraft(id: UUID) throws -> TransactionEditDraft {
        throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: id)
    }

    func updateTransaction(draft: TransactionEditDraft) throws {}

    func deleteTransaction(id: UUID) throws {
        try deleteHandler(id)
    }
}

private final class UndoServiceMock: TransactionUndoProviding {
    private(set) var undoStack: [UndoableTransaction] = []

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    func recordTransaction(_ transaction: UndoableTransaction) {
        undoStack.append(transaction)
    }

    func undoLastTransaction() -> UndoableTransaction? {
        guard !undoStack.isEmpty else {
            return nil
        }
        return undoStack.removeLast()
    }

    func clearUndoStack() {
        undoStack.removeAll()
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

    @Test("Test: category options include income category for direct selection")
    func loadOptions_withIncomeCategory_allowsIncomeCategorySelection() {
        let paymentMethodID = UUID()
        let expenseCategoryID = UUID()
        let incomeCategoryID = UUID()
        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: UUID(), duplicateDetected: false)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(
                    TransactionFormOptions(
                        accounts: [TransactionFormAccountOption(id: paymentMethodID, name: "Cash")],
                        categories: [
                            TransactionFormCategoryOption(id: expenseCategoryID, name: "Food", icon: "fork.knife", type: "expense"),
                            TransactionFormCategoryOption(id: incomeCategoryID, name: "Income", icon: "arrow.down.circle.fill", type: "income")
                        ]
                    )
                )
            )
        )

        viewModel.loadOptions()
        viewModel.selectedCategoryID = incomeCategoryID

        #expect(viewModel.categoryOptions.contains(where: { $0.id == incomeCategoryID }))
        #expect(viewModel.selectedCategoryID == incomeCategoryID)
    }

    @Test("Test: undo reverts last saved transaction")
    func undoLastSave_afterSuccessfulSave_deletesSavedTransactionAndResetsUndoState() {
        let expectedID = UUID()
        var deletedID: UUID?
        let undoService = UndoServiceMock()

        let viewModel = AddTransactionViewModel(
            transactionEntryService: TransactionEntrySavingMock { _, _, _, _, _, _, _ in
                TransactionEntryResult(transactionID: expectedID, duplicateDetected: false)
            },
            optionsProvider: TransactionFormOptionsProvidingMock(
                result: .success(TransactionFormOptions(accounts: [], categories: []))
            ),
            undoService: undoService,
            mutationService: TransactionMutatingMock(deleteHandler: { id in
                deletedID = id
            })
        )

        viewModel.selectedAccountID = UUID()
        viewModel.amountText = "12000"
        viewModel.save()

        #expect(viewModel.canUndoLastSave == true)
        #expect(viewModel.lastSavedTransactionID == expectedID)

        viewModel.undoLastSave()

        #expect(deletedID == expectedID)
        #expect(viewModel.canUndoLastSave == false)
        #expect(viewModel.lastSavedTransactionID == nil)
        #expect(viewModel.saveMessage == "Transaction undone")
    }
}
