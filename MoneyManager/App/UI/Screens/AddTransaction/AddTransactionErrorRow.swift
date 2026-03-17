import SwiftUI

struct AddTransactionErrorRow: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .foregroundStyle(.red)
            .font(.subheadline)
    }
}
