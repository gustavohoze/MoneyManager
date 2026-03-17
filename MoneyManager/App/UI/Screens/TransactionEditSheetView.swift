import SwiftUI

struct TransactionEditSheetView: View {
    let state: TransactionEditState
    let onCancel: () -> Void
    let onSave: (TransactionEditDraft) -> Void

    @StateObject private var viewModel = TransactionEditSheetViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Amount")) {
                    TextField(String(localized: "Amount"), text: $viewModel.editAmountText)
                        .keyboardType(.decimalPad)
                }

                Section(String(localized: "Merchant")) {
                    TextField(String(localized: "Merchant"), text: $viewModel.editMerchantRaw)
                }

                Section(String(localized: "Category")) {
                    Picker(String(localized: "Category"), selection: $viewModel.editSelectedCategoryID) {
                        ForEach(state.options.categories) { option in
                            Text(option.name).tag(Optional(option.id))
                        }
                    }
                }

                Section(String(localized: "PaymentMethod")) {
                    Picker(String(localized: "PaymentMethod"), selection: $viewModel.editSelectedAccountID) {
                        ForEach(state.options.accounts) { option in
                            Text(option.name).tag(Optional(option.id))
                        }
                    }
                }

                Section(String(localized: "Date")) {
                    DatePicker(String(localized: "Transaction Date"), selection: $viewModel.editDate, displayedComponents: .date)
                }

                Section(String(localized: "Note")) {
                    TextField(String(localized: "Optional Note"), text: $viewModel.editNote)
                }
            }
            .navigationTitle(String(localized: "Edit Transaction"))
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
            }
            .onAppear {
                viewModel.load(from: state)
            }
        }
    }
}
