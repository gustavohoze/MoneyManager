import SwiftUI

struct TransactionEditNoteField: View {
    @Binding var value: String
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Note"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            TextField(String(localized: "Optional Note"), text: $value)
        }
        .financeCard(palette: palette)
    }
}
