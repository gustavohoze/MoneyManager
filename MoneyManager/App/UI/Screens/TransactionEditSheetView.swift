import SwiftUI

struct TransactionEditSheetView: View {
    let state: TransactionEditState
    let onCancel: () -> Void
    let onSave: (TransactionEditDraft) -> Void
    let onDelete: () -> Void

    @StateObject private var viewModel = TransactionEditSheetViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    TransactionEditAmountField(
                        value: $viewModel.editAmountText,
                        palette: palette
                    )

                    TransactionEditMerchantField(
                        value: $viewModel.editMerchantRaw,
                        palette: palette
                    )

                    HStack(spacing: 12) {
                        TransactionEditCategoryField(
                            selectedID: $viewModel.editSelectedCategoryID,
                            options: state.options.categories,
                            palette: palette
                        )
                        .frame(maxWidth: .infinity)

                        TransactionEditAccountField(
                            selectedID: $viewModel.editSelectedAccountID,
                            options: state.options.accounts,
                            palette: palette
                        )
                        .frame(maxWidth: .infinity)
                    }

                    TransactionEditDateField(
                        value: $viewModel.editDate,
                        palette: palette
                    )

                    TransactionEditNoteField(
                        value: $viewModel.editNote,
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
                    Spacer()
                    Button(String(localized: "Done")) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                viewModel.load(from: state)
            }
        }
    }
}
