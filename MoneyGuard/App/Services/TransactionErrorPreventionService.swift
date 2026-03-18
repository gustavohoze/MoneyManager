import Foundation
import CoreData

protocol TransactionErrorPreventionProviding {
    func averageTransactionAmount() throws -> Double
    func shouldWarnAboutAmount(_ amount: Double) throws -> Bool
    func suggestedAmountIfTypo(_ amount: Double) throws -> Double?
}

struct TransactionErrorPreventionService: TransactionErrorPreventionProviding {
    private let transactionRepository: TransactionRepository
    private let typoMultiplier: Double = 3.0

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func averageTransactionAmount() throws -> Double {
        let allTransactions = try transactionRepository.fetchTransactions()
        guard !allTransactions.isEmpty else {
            return 0
        }

        let total = allTransactions.reduce(0.0) { sum, transaction in
            let amount = (transaction.value(forKey: "amount") as? Double) ?? 0
            return sum + amount
        }

        return total / Double(allTransactions.count)
    }

    func shouldWarnAboutAmount(_ amount: Double) throws -> Bool {
        let average = try averageTransactionAmount()
        guard average > 0 else {
            return false
        }
        return amount > (average * typoMultiplier)
    }

    func suggestedAmountIfTypo(_ amount: Double) throws -> Double? {
        guard try shouldWarnAboutAmount(amount) else {
            return nil
        }

        // Try to suggest amount by removing a zero
        let amountString = String(format: "%.0f", amount)
        guard amountString.count > 1 else {
            return nil
        }

        let suggestedString = String(amountString.dropLast())
        return Double(suggestedString)
    }
}
