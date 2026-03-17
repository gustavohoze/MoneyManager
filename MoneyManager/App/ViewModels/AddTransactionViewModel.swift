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
    private static let amountDisplayFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSize = 3
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    // MARK: - Basic Input
    @Published var amountText = ""
    @Published var merchantRaw = ""
    @Published var selectedCategoryID: UUID?
    @Published var selectedAccountID: UUID? {
        didSet {
            syncCurrencyWithSelectedAccount()
        }
    }
    @Published var selectedDate = Date()
    @Published var note = ""
    @Published var currency = AppCurrency.currentCode

    // MARK: - Options
    @Published private(set) var accountOptions: [TransactionFormAccountOption] = []
    @Published private(set) var categoryOptions: [TransactionFormCategoryOption] = []

    // MARK: - UI State
    @Published private(set) var isSaving = false
    @Published private(set) var duplicateWarning = false
    @Published private(set) var lastSavedTransactionID: UUID?
    @Published private(set) var saveMessage: String?
    @Published private(set) var canUndoLastSave = false
    @Published private(set) var error: AddTransactionViewModelError?

    // MARK: - Milestone 2 Features
    @Published private(set) var merchantSuggestions: [MerchantSuggestion] = []
    @Published private(set) var saveCooldown = false

    // MARK: - Private Services
    private let transactionEntryService: TransactionEntrySaving
    private let optionsProvider: TransactionFormOptionsProviding
    private let merchantCategorySuggester: MerchantCategorySuggesting?
    private let merchantSuggestionProvider: MerchantSuggestionProviding?
    private let accountAutoSelection: AccountAutoSelectionProviding?
    private let errorPrevention: TransactionErrorPreventionProviding?
    private let merchantMemoryRecorder: MerchantMemoryRecording?
    private let undoService: TransactionUndoProviding?
    private let mutationService: TransactionMutating?

    init(
        transactionEntryService: TransactionEntrySaving,
        optionsProvider: TransactionFormOptionsProviding,
        merchantCategorySuggester: MerchantCategorySuggesting? = nil,
        merchantSuggestionProvider: MerchantSuggestionProviding? = nil,
        accountAutoSelection: AccountAutoSelectionProviding? = nil,
        errorPrevention: TransactionErrorPreventionProviding? = nil,
        merchantMemoryRecorder: MerchantMemoryRecording? = nil,
        undoService: TransactionUndoProviding? = nil,
        mutationService: TransactionMutating? = nil
    ) {
        self.transactionEntryService = transactionEntryService
        self.optionsProvider = optionsProvider
        self.merchantCategorySuggester = merchantCategorySuggester
        self.merchantSuggestionProvider = merchantSuggestionProvider
        self.accountAutoSelection = accountAutoSelection
        self.errorPrevention = errorPrevention
        self.merchantMemoryRecorder = merchantMemoryRecorder
        self.undoService = undoService
        self.mutationService = mutationService
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

            syncCurrencyWithSelectedAccount()

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

    private func syncCurrencyWithSelectedAccount() {
        guard let selectedAccountID,
              let account = accountOptions.first(where: { $0.id == selectedAccountID })
        else {
            return
        }

        currency = account.currency
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

    func normalizeAmountInput(_ newValue: String) -> String {
        let digits = newValue.filter { $0.isNumber }
        guard let number = Double(digits), number > 0 else {
            return digits
        }

        return Self.amountDisplayFormatter.string(from: NSNumber(value: number)) ?? digits
    }

    func didChangeAmountText(_ newValue: String) {
        let normalized = normalizeAmountInput(newValue)
        if normalized != amountText {
            amountText = normalized
        }
    }

    func saveFromForm() {
        save()
    }

    var canSaveForm: Bool {
        guard selectedAccountID != nil else {
            return false
        }

        guard let amount = Double(amountText.filter { $0.isNumber }), amount > 0 else {
            return false
        }

        return !isSaving
    }

    func selectedAccountName(
        from accounts: [TransactionFormAccountOption],
        selectedAccountID: UUID?
    ) -> String {
        accounts.first(where: { $0.id == selectedAccountID })?.name ?? "Select Payment Method"
    }

    func selectedCategoryName(
        from categories: [TransactionFormCategoryOption],
        selectedCategoryID: UUID?
    ) -> String {
        categories.first(where: { $0.id == selectedCategoryID })?.name ?? "Select Category"
    }

    func errorMessage(for error: AddTransactionViewModelError) -> String {
        switch error {
        case .missingAccount:
            return String(localized: "Please select a payment method")
        case .invalidAmount:
            return String(localized: "Amount must be greater than zero")
        case .saveFailed:
            return String(localized: "Could not save transaction")
        case .amountTooLarge:
            return String(localized: "Amount verification needed")
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

            duplicateWarning = result.duplicateDetected
            lastSavedTransactionID = result.transactionID
            canUndoLastSave = mutationService != nil
            saveMessage = String(localized: "Transaction saved")
            error = nil

            undoService?.recordTransaction(
                UndoableTransaction(
                    id: result.transactionID,
                    paymentMethodID: paymentMethodID,
                    amount: amount,
                    currency: currency,
                    date: selectedDate,
                    merchantRaw: merchantRaw,
                    categoryID: selectedCategoryID,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note,
                    timestampCreated: Date()
                )
            )

            try accountAutoSelection?.recordAccountUsage(paymentMethodID: paymentMethodID)

            // Clear form
            resetForm()
        } catch let entryError as TransactionEntryError {
            switch entryError {
            case .invalidAmount:
                error = .invalidAmount
            }
        } catch {
            self.error = .saveFailed
            saveMessage = nil
            canUndoLastSave = false
        }
    }

    func undoLastSave() {
        guard canUndoLastSave else {
            return
        }

        guard let transactionID = lastSavedTransactionID else {
            return
        }

        do {
            if let mutationService {
                try mutationService.deleteTransaction(id: transactionID)
            }
            _ = undoService?.undoLastTransaction()
            canUndoLastSave = false
            duplicateWarning = false
            saveMessage = String(localized: "Transaction undone")
            lastSavedTransactionID = nil
            error = nil
        } catch {
            self.error = .saveFailed
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

    // MARK: - Layout Helpers (for Views)
    
    var amountFieldFontSize: Double {
        let count = amountText.count
        if count > 12 {
            return 32
        } else if count > 9 {
            return 40
        } else if count > 6 {
            return 48
        } else {
            return 56
        }
    }

    var shouldShowDetailsSection: Bool {
        !categoryOptions.isEmpty || !accountOptions.isEmpty
    }

    var shouldShowErrorSection: Bool {
        if let error = error {
            return !error.isAmountWarning
        }
        return false
    }

    var selectedCategoryOption: TransactionFormCategoryOption? {
        categoryOptions.first(where: { $0.id == selectedCategoryID })
    }

    var selectedAccountOption: TransactionFormAccountOption? {
        accountOptions.first(where: { $0.id == selectedAccountID })
    }
}

private extension AddTransactionViewModelError {
    var isAmountWarning: Bool {
        if case .amountTooLarge = self { return true }
        return false
    }
}
