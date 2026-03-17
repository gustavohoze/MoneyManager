import SwiftUI

struct AddTransactionErrorCard: View {
    let error: AddTransactionViewModelError
    let errorMessage: String
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .financeCard(palette: palette)
    }
}
