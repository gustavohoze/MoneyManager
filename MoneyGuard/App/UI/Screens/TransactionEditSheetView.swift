import SwiftUI

struct TransactionEditSheetView: View {
    let state: TransactionEditState
    let onCancel: () -> Void
    let onSave: (TransactionEditDraft) -> Void
    let onDelete: () -> Void

    @StateObject private var viewModel = TransactionEditSheetViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: AddTransactionFormField?

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    TransactionEditAmountField(
                        value: $viewModel.editAmountText,
                        focusedField: $focusedField,
                        palette: palette
                    )

                    TransactionEditMerchantField(
                        value: $viewModel.editMerchantRaw,
                        focusedField: $focusedField,
                        palette: palette
                    )

                    HStack(spacing: 12) {
                        AddTransactionCategoryPickerCard(
                            selectedCategory: selectedCategoryOption,
                            categories: state.options.categories,
                            palette: palette,
                            onSelect: { viewModel.editSelectedCategoryID = $0 }
                        )
                        .frame(maxWidth: .infinity)

                        AddTransactionAccountPickerCard(
                            selectedAccount: selectedAccountOption,
                            accounts: state.options.accounts,
                            palette: palette,
                            onSelect: { viewModel.editSelectedAccountID = $0 }
                        )
                        .frame(maxWidth: .infinity)
                    }

                    TransactionEditDateField(
                        value: $viewModel.editDate,
                        palette: palette
                    )

                    TransactionEditNoteField(
                        value: $viewModel.editNote,
                        focusedField: $focusedField,
                        palette: palette
                    )

                    TransactionEditDeleteButton(action: onDelete)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle(String(localized: "Edit Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) {
                        guard let updatedDraft = viewModel.makeDraft(from: state) else {
                            return
                        }
                        onSave(updatedDraft)
                    }
                    .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .amount {
                        Spacer()
                        Button(String(localized: "Done")) {
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                viewModel.load(from: state)
            }
        }
    }

    private var selectedCategoryOption: TransactionFormCategoryOption? {
        state.options.categories.first(where: { $0.id == viewModel.editSelectedCategoryID })
    }

    private var selectedAccountOption: TransactionFormAccountOption? {
        state.options.accounts.first(where: { $0.id == viewModel.editSelectedAccountID })
    }
}
