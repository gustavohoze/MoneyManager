import SwiftUI

struct AddTransactionScreen: View {
    @ObservedObject var viewModel: AddTransactionViewModel
    @FocusState private var focusedField: AddTransactionFormField?

    var body: some View {
        NavigationStack {
            Form {
                AddTransactionAmountSection(
                    amountText: $viewModel.amountText,
                    focusedField: $focusedField,
                    onAmountTextChange: { viewModel.didChangeAmountText($0) }
                )

                AddTransactionMerchantSection(
                    merchantText: $viewModel.merchantRaw,
                    suggestions: viewModel.merchantSuggestions,
                    focusedField: $focusedField,
                    onSelectSuggestion: { viewModel.selectMerchantSuggestion($0) },
                    onMerchantChange: { viewModel.updateMerchantSuggestions(for: $0) }
                )

                if !viewModel.categoryOptions.isEmpty || !viewModel.accountOptions.isEmpty {
                    AddTransactionCategoryAccountRow(
                        categories: viewModel.categoryOptions,
                        accounts: viewModel.accountOptions,
                        selectedCategoryID: viewModel.selectedCategoryID,
                        selectedAccountID: viewModel.selectedAccountID,
                        onSelectCategory: { viewModel.selectedCategoryID = $0 },
                        onSelectAccount: { viewModel.selectedAccountID = $0 }
                    )
                }

                AddTransactionDetailsSection(
                    selectedDate: $viewModel.selectedDate,
                    note: $viewModel.note,
                    focusedField: $focusedField
                )

                AddTransactionSaveSection(
                    amountText: viewModel.amountText,
                    isSaving: viewModel.isSaving,
                    onSave: {
                        focusedField = nil
                        viewModel.saveFromForm()
                    }
                )

                if let error = viewModel.error, !error.isAmountWarning {
                    Section {
                        AddTransactionErrorRow(message: viewModel.errorMessage(for: error))
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let undoMessage = viewModel.undoMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.large)

                        Text(undoMessage)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        if viewModel.canUndo {
                            Button("Undo") {
                                viewModel.undoLastTransaction()
                            }
                            .font(.subheadline.weight(.semibold))
                        }

                        if viewModel.duplicateWarning {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                                .imageScale(.medium)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.undoMessage)
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadOptions() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }
}

private extension AddTransactionViewModelError {
    var isAmountWarning: Bool {
        if case .amountTooLarge = self { return true }
        return false
    }
}

// MARK: - Preview

#Preview {
    AddTransactionScreen(viewModel: .previewInstance)
}