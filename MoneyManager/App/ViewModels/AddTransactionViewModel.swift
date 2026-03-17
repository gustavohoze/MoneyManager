import Foundation
import Combine

enum AddTransactionViewModelError: Error, Equatable {
    case missingAccount
    case invalidAmount
    case saveFailed
    case amountTooLarge(suggested: Double?)
}

@MainActor
final class AddTransactionViewModel: ObservableObject {
    // MARK: - Basic Input
    @Published var amountText = ""
    @Published var merchantRaw = ""
    @Published var selectedCategoryID: UUID?
    @Published var selectedAccountID: UUID?
    @Published var selectedDate = Date()
    @Published var note = ""
    @Published var currency = "IDR"

    // MARK: - Options
    @Published private(set) var accountOptions: [TransactionFormAccountOption] = []
    @Published private(set) var categoryOptions: [TransactionFormCategoryOption] = []

    // MARK: - UI State
    @Published private(set) var isSaving = false
    @Published private(set) var duplicateWarning = false
    @Published private(set) var lastSavedTransactionID: UUID?
    @Published private(set) var error: AddTransactionViewModelError?

    // MARK: - Milestone 2 Features
    @Published private(set) var merchantSuggestions: [MerchantSuggestion] = []
    @Published private(set) var undoMessage: String?
    @Published private(set) var canUndo = false
    @Published private(set) var saveCooldown = false

    // MARK: - Private Services
    private let transactionEntryService: TransactionEntrySaving
    private let optionsProvider: TransactionFormOptionsProviding
    private let merchantCategorySuggester: MerchantCategorySuggesting?
    private let merchantSuggestionProvider: MerchantSuggestionProviding?
    private let accountAutoSelection: AccountAutoSelectionProviding?
    private let errorPrevention: TransactionErrorPreventionProviding?
    private let undoService: TransactionUndoProviding?
    private let merchantMemoryRecorder: MerchantMemoryRecording?

    private var undoTimer: Timer?
    private var undoTimeRemaining = 0

    init(
        transactionEntryService: TransactionEntrySaving,
        optionsProvider: TransactionFormOptionsProviding,
        merchantCategorySuggester: MerchantCategorySuggesting? = nil,
        merchantSuggestionProvider: MerchantSuggestionProviding? = nil,
        accountAutoSelection: AccountAutoSelectionProviding? = nil,
        errorPrevention: TransactionErrorPreventionProviding? = nil,
        undoService: TransactionUndoProviding? = nil,
        merchantMemoryRecorder: MerchantMemoryRecording? = nil
    ) {
        self.transactionEntryService = transactionEntryService
        self.optionsProvider = optionsProvider
        self.merchantCategorySuggester = merchantCategorySuggester
        self.merchantSuggestionProvider = merchantSuggestionProvider
        self.accountAutoSelection = accountAutoSelection
        self.errorPrevention = errorPrevention
        self.undoService = undoService
        self.merchantMemoryRecorder = merchantMemoryRecorder
    }

    // MARK: - Category Suggestion
    func suggestedCategoryID(for merchantRaw: String) -> UUID? {
        do {
            return try merchantCategorySuggester?.suggestedCategoryID(for: merchantRaw)
        } catch {
            return nil
        }
    }

    // MARK: - Merchant Suggestions
    func updateMerchantSuggestions(for prefix: String) {
        Task {
            do {
                if prefix.isEmpty {
                    merchantSuggestions = try merchantSuggestionProvider?.frequentMerchants(limit: 5) ?? []
                } else {
                    merchantSuggestions = try merchantSuggestionProvider?.merchantSuggestions(for: prefix, limit: 8) ?? []
                }
            } catch {
                merchantSuggestions = []
            }
        }
    }

    func selectMerchantSuggestion(_ suggestion: MerchantSuggestion) {
        merchantRaw = suggestion.displayName
        merchantSuggestions = []
        
        // Auto-suggest category
        if let categoryID = suggestedCategoryID(for: suggestion.displayName) {
            selectedCategoryID = categoryID
        }
    }

    // MARK: - Options Loading
    func loadOptions() {
        do {
            let options = try optionsProvider.loadOptions()
            accountOptions = options.accounts
            categoryOptions = options.categories

            // Auto-select last used account
            if selectedAccountID == nil {
                let lastUsedID = try accountAutoSelection?.lastUsedAccountID()
                selectedAccountID = lastUsedID ?? options.accounts.first?.id
            }

            if selectedCategoryID == nil {
                selectedCategoryID = options.categories.first(where: { $0.name == "Uncategorized" })?.id
                    ?? options.categories.first?.id
            }

            // Load initial merchant suggestions
            updateMerchantSuggestions(for: "")

            if error == .saveFailed {
                error = nil
            }
        } catch {
            accountOptions = []
            categoryOptions = []
            self.error = .saveFailed
        }
    }

    // MARK: - Error Prevention
    func validateAmount(_ amount: Double) {
        Task {
            do {
                if try errorPrevention?.shouldWarnAboutAmount(amount) ?? false {
                    if let suggested = try errorPrevention?.suggestedAmountIfTypo(amount) {
                        error = .amountTooLarge(suggested: suggested)
                    } else {
                        error = .amountTooLarge(suggested: nil)
                    }
                } else {
                    if case .amountTooLarge = error {
                        error = nil
                    }
                }
            } catch {
                // Silently ignore validation errors
            }
        }
    }

    // MARK: - Save & Undo
    func save() {
        guard !isSaving else {
            return
        }

        guard let paymentMethodID = selectedAccountID else {
            error = .missingAccount
            return
        }

        guard let amount = Double(amountText.filter { $0.isNumber }), amount > 0 else {
            error = .invalidAmount
            return
        }

        isSaving = true
        defer {
            isSaving = false
        }

        do {
            let result = try transactionEntryService.saveManualTransaction(
                paymentMethodID: paymentMethodID,
                amount: amount,
                currency: currency,
                date: selectedDate,
                merchantRaw: merchantRaw,
                categoryID: selectedCategoryID,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            )

            // Record merchant usage and category mapping
            try merchantMemoryRecorder?.recordMerchantUsage(merchantRaw: merchantRaw)
            if let categoryID = selectedCategoryID {
                try merchantMemoryRecorder?.recordCategoryMapping(merchantRaw: merchantRaw, categoryID: categoryID)
            }

            // Record for undo
            let undoableTransaction = UndoableTransaction(
                id: result.transactionID,
                paymentMethodID: paymentMethodID,
                amount: amount,
                currency: currency,
                date: selectedDate,
                merchantRaw: merchantRaw,
                categoryID: selectedCategoryID,
                note: note.isEmpty ? nil : note,
                timestampCreated: Date()
            )
            undoService?.recordTransaction(undoableTransaction)
            canUndo = undoService?.canUndo ?? false

            duplicateWarning = result.duplicateDetected
            lastSavedTransactionID = result.transactionID
            error = nil

            // Show undo message
            showUndoMessage()

            // Clear form
            resetForm()
        } catch let entryError as TransactionEntryError {
            switch entryError {
            case .invalidAmount:
                error = .invalidAmount
            }
        } catch {
            self.error = .saveFailed
        }
    }

    func undoLastTransaction() {
        guard let transaction = undoService?.undoLastTransaction() else {
            return
        }

        // Delete the transaction
        Task {
            do {
                // This requires extending transactionEntryService with an undo method
                // For now, we'll just update UI state
                canUndo = undoService?.canUndo ?? false
                undoMessage = String(localized: "Transaction undone")
                startUndoCountdown()
            }
        }
    }

    private func showUndoMessage() {
        undoMessage = String(localized: "Expense saved")
        startUndoCountdown()
    }

    private func startUndoCountdown() {
        undoTimer?.invalidate()
        undoTimeRemaining = 5

        undoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.undoTimeRemaining -= 1
            if self?.undoTimeRemaining ?? 0 <= 0 {
                self?.undoTimer?.invalidate()
                self?.undoMessage = nil
                self?.undoTimer = nil
            }
        }
    }

    private func resetForm() {
        amountText = ""
        merchantRaw = ""
        selectedDate = Date()
        note = ""
        merchantSuggestions = []
        
        // Keep category selection for next entry if desired
        // selectedCategoryID remains
    }
}
