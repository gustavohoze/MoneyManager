import Foundation

struct UndoableTransaction: Identifiable, Equatable {
    let id: UUID
    let paymentMethodID: UUID
    let amount: Double
    let currency: String
    let date: Date
    let merchantRaw: String
    let categoryID: UUID?
    let note: String?
    let timestampCreated: Date

    static func == (lhs: UndoableTransaction, rhs: UndoableTransaction) -> Bool {
        lhs.id == rhs.id && lhs.timestampCreated == rhs.timestampCreated
    }
}

protocol TransactionUndoProviding {
    var undoStack: [UndoableTransaction] { get }
    var canUndo: Bool { get }
    func recordTransaction(_ transaction: UndoableTransaction)
    func undoLastTransaction() -> UndoableTransaction?
    func clearUndoStack()
}

class TransactionUndoService: TransactionUndoProviding {
    private let maxUndoItems = 20
    private(set) var undoStack: [UndoableTransaction] = []

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    func recordTransaction(_ transaction: UndoableTransaction) {
        undoStack.append(transaction)
        if undoStack.count > maxUndoItems {
            undoStack.removeFirst()
        }
    }

    func undoLastTransaction() -> UndoableTransaction? {
        guard canUndo else {
            return nil
        }
        return undoStack.removeLast()
    }

    func clearUndoStack() {
        undoStack.removeAll()
    }
}
