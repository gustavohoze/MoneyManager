import SwiftUI

struct TransactionEditSheetView: View {
    let state: TransactionEditState
    let onCancel: () -> Void
    let onSave: (TransactionEditDraft) -> Void

    @State private var editAmountText = ""
    @State private var editMerchantRaw = ""
    @State private var editSelectedCategoryID: UUID?
    @State private var editSelectedAccountID: UUID?
    @State private var editDate = Date()
    @State private var editNote = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Amount")) {
                    TextField(String(localized: "Amount"), text: $editAmountText)
                        .keyboardType(.decimalPad)
                }

                Section(String(localized: "Merchant")) {
                    TextField(String(localized: "Merchant"), text: $editMerchantRaw)
                }

                Section(String(localized: "Category")) {
                    Picker(String(localized: "Category"), selection: $editSelectedCategoryID) {
                        ForEach(state.options.categories) { option in
                            Text(option.name).tag(Optional(option.id))
                        }
                    }
                }

                Section(String(localized: "PaymentMethod")) {
                    Picker(String(localized: "PaymentMethod"), selection: $editSelectedAccountID) {
                        ForEach(state.options.accounts) { option in
                            Text(option.name).tag(Optional(option.id))
                        }
                    }
                }

                Section(String(localized: "Date")) {
                    DatePicker(String(localized: "Transaction Date"), selection: $editDate, displayedComponents: .date)
                }

                Section(String(localized: "Note")) {
                    TextField(String(localized: "Optional Note"), text: $editNote)
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
                        guard
                            let paymentMethodID = editSelectedAccountID,
                            let amount = Double(editAmountText),
                            amount > 0
                        else {
                            return
                        }

                        let updatedDraft = TransactionEditDraft(
                            id: state.draft.id,
                            paymentMethodID: paymentMethodID,
                            amount: amount,
                            currency: state.draft.currency,
                            date: editDate,
                            merchantRaw: editMerchantRaw,
                            categoryID: editSelectedCategoryID,
                            note: editNote
                        )

                        onSave(updatedDraft)
                    }
                    .disabled(editSelectedAccountID == nil || Double(editAmountText) == nil || (Double(editAmountText) ?? 0) <= 0)
                }
            }
            .onAppear {
                editAmountText = String(format: "%.0f", state.draft.amount)
                editMerchantRaw = state.draft.merchantRaw
                editSelectedCategoryID = state.draft.categoryID ?? state.options.categories.first?.id
                editSelectedAccountID = state.draft.paymentMethodID
                editDate = state.draft.date
                editNote = state.draft.note ?? ""
            }
        }
    }
}
