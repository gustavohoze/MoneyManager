import SwiftUI

struct TransactionEditMerchantField: View {
    @Binding var value: String
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Merchant"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            TextField(String(localized: "Merchant"), text: $value)
                .focused(focusedField, equals: .merchant)
        }
        .financeCard(palette: palette)
    }
}
