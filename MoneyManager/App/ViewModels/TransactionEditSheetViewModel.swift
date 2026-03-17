import Foundation
import Combine

@MainActor
final class TransactionEditSheetViewModel: ObservableObject {
    @Published var editAmountText = ""
    @Published var editMerchantRaw = ""
    @Published var editSelectedCategoryID: UUID?
    @Published var editSelectedAccountID: UUID?
    @Published var editDate = Date()
    @Published var editNote = ""

    func load(from state: TransactionEditState) {
        editAmountText = String(format: "%.0f", state.draft.amount)
        editMerchantRaw = state.draft.merchantRaw
        editSelectedCategoryID = state.draft.categoryID ?? state.options.categories.first?.id
        editSelectedAccountID = state.draft.paymentMethodID
        editDate = state.draft.date
        editNote = state.draft.note ?? ""
    }

    var canSave: Bool {
        guard let amount = Double(editAmountText), amount > 0 else {
            return false
        }
        return editSelectedAccountID != nil
    }

    func makeDraft(from state: TransactionEditState) -> TransactionEditDraft? {
        guard
            let paymentMethodID = editSelectedAccountID,
            let amount = Double(editAmountText),
            amount > 0
        else {
            return nil
        }

        return TransactionEditDraft(
            id: state.draft.id,
            paymentMethodID: paymentMethodID,
            amount: amount,
            currency: state.draft.currency,
            date: editDate,
            merchantRaw: editMerchantRaw,
            categoryID: editSelectedCategoryID,
            note: editNote
        )
    }
}
