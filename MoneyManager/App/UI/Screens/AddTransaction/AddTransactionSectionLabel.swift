import SwiftUI

struct AddTransactionSectionLabel: View {
    let text: String
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.accent)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
