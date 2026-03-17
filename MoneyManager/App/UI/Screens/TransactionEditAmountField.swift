import SwiftUI

struct TransactionEditAmountField: View {
    @Binding var value: String
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Amount"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            TextField(String(localized: "Amount"), text: $value)
                .keyboardType(.decimalPad)
        }
        .financeCard(palette: palette)
    }
}
