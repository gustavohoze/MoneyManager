import Foundation

enum TransactionEntryError: LocalizedError, Equatable {
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Transaction amount must be greater than zero"
        }
    }
}
