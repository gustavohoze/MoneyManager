import SwiftUI

struct TransactionEditDateField: View {
    @Binding var value: Date
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Date"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            DatePicker(String(localized: "Transaction Date"), selection: $value, displayedComponents: .date)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }
}
