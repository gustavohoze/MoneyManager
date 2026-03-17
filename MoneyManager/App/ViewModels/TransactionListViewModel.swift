import Foundation
import Combine

struct TransactionEditState: Identifiable, Equatable {
    var draft: TransactionEditDraft
    let options: TransactionFormOptions

    var id: UUID {
        draft.id
    }
}

@MainActor
final class TransactionListViewModel: ObservableObject {
    @Published private(set) var sections: [TransactionListSection] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published var editState: TransactionEditState?

    private let dataProvider: TransactionListDataProviding
    private let mutationService: TransactionMutating
    private let optionsProvider: TransactionFormOptionsProviding

    init(
        dataProvider: TransactionListDataProviding,
        mutationService: TransactionMutating = NoOpTransactionMutationService(),
        optionsProvider: TransactionFormOptionsProviding
    ) {
        self.dataProvider = dataProvider
        self.mutationService = mutationService
        self.optionsProvider = optionsProvider
    }

    func load(asOf date: Date = Date()) {
        do {
            sections = try dataProvider.loadSections(asOf: date)
            errorMessage = nil
        } catch {
            sections = []
            errorMessage = error.localizedDescription
        }
    }

    func deleteTransaction(id: UUID, asOf date: Date = Date()) {
        do {
            try mutationService.deleteTransaction(id: id)
            actionMessage = "Transaction deleted."
            load(asOf: date)
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func beginEdit(id: UUID) {
        do {
            let draft = try mutationService.loadEditDraft(id: id)
            let options = try optionsProvider.loadOptions()
            editState = TransactionEditState(draft: draft, options: options)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelEdit() {
        editState = nil
    }

    func saveEdit(draft: TransactionEditDraft, asOf date: Date = Date()) {
        do {
            try mutationService.updateTransaction(draft: draft)
            actionMessage = "Transaction updated."
            editState = nil
            load(asOf: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func currencyText(_ value: Double) -> String {
        value.formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }
}
