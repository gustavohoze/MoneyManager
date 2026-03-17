import SwiftUI

struct AddTransactionScreen: View {
    @ObservedObject var viewModel: AddTransactionViewModel
    var autoFocusAmountOnAppear: Bool = false
    @FocusState private var focusedField: AddTransactionFormField?
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.pageBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Hero amount card
                        AddTransactionAmountHeroCard(
                            amountText: $viewModel.amountText,
                            fontSize: viewModel.amountFieldFontSize,
                            focusedField: $focusedField,
                            palette: palette,
                            onAmountChange: viewModel.didChangeAmountText
                        )

                        // Merchant section
                        AddTransactionSectionLabel(text: String(localized: "Merchant"), palette: palette)

                        AddTransactionMerchantInputCard(
                            merchantText: $viewModel.merchantRaw,
                            suggestions: viewModel.merchantSuggestions,
                            palette: palette,
                            onMerchantChange: viewModel.updateMerchantSuggestions,
                            onSelectSuggestion: viewModel.selectMerchantSuggestion
                        )

                        // Details section (Category & Account)
                        if viewModel.shouldShowDetailsSection {
                            AddTransactionSectionLabel(text: String(localized: "Details"), palette: palette)

                            HStack(spacing: 12) {
                                if !viewModel.categoryOptions.isEmpty {
                                    AddTransactionCategoryPickerCard(
                                        selectedCategory: viewModel.selectedCategoryOption,
                                        categories: viewModel.categoryOptions,
                                        palette: palette,
                                        onSelect: { viewModel.selectedCategoryID = $0 }
                                    )
                                }

                                if !viewModel.accountOptions.isEmpty {
                                    AddTransactionAccountPickerCard(
                                        selectedAccount: viewModel.selectedAccountOption,
                                        accounts: viewModel.accountOptions,
                                        palette: palette,
                                        onSelect: { viewModel.selectedAccountID = $0 }
                                    )
                                }
                            }
                        }

                        // Metadata section (Date & Note)
                        AddTransactionSectionLabel(text: String(localized: "Transaction Info"), palette: palette)

                        AddTransactionMetadataCard(
                            selectedDate: $viewModel.selectedDate,
                            note: $viewModel.note,
                            palette: palette
                        )

                        // Error display
                        if viewModel.shouldShowErrorSection,
                           let error = viewModel.error {
                            AddTransactionErrorCard(
                                error: error,
                                errorMessage: viewModel.errorMessage(for: error),
                                palette: palette
                            )
                        }

                        // Save button
                        AddTransactionSaveButtonCard(
                            isSaving: viewModel.isSaving,
                            isEnabled: viewModel.canSaveForm,
                            palette: palette,
                            onSave: {
                                focusedField = nil
                                viewModel.saveFromForm()
                            }
                        )

                        if let saveMessage = viewModel.saveMessage {
                            AddTransactionUndoRow(
                                message: saveMessage,
                                canUndo: viewModel.canUndoLastSave,
                                duplicateWarning: viewModel.duplicateWarning,
                                onUndo: {
                                    focusedField = nil
                                    viewModel.undoLastSave()
                                }
                            )
                            .padding(.top, 4)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
            }
            .navigationTitle(String(localized: "New Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                viewModel.loadOptions()
                if autoFocusAmountOnAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        focusedField = .amount
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddTransactionScreen(viewModel: .previewInstance)
}
