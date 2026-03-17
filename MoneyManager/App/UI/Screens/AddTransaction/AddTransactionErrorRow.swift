import SwiftUI

struct AddTransactionErrorRow: View {
    var error: AddTransactionViewModelError

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .foregroundStyle(.red)
            .font(.subheadline)
    }

    private var message: String {
        switch error {
        case .missingAccount:   return String(localized: "Please select an account")
        case .invalidAmount:    return String(localized: "Amount must be greater than zero")
        case .saveFailed:       return String(localized: "Could not save transaction")
        case .amountTooLarge:   return String(localized: "Amount verification needed")
        }
    }
}
