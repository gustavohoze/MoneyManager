import SwiftUI

struct TransactionEditAccountField: View {
    @Binding var selectedID: UUID?
    let options: [TransactionFormAccountOption]
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Payment Method"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            Picker(String(localized: "Payment Method"), selection: $selectedID) {
                ForEach(options) { option in
                    Text(option.name).tag(Optional(option.id))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }
}
