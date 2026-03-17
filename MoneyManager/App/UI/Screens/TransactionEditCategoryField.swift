import SwiftUI

struct TransactionEditCategoryField: View {
    @Binding var selectedID: UUID?
    let options: [TransactionFormCategoryOption]
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Category"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            Picker(String(localized: "Category"), selection: $selectedID) {
                ForEach(options) { option in
                    Text(option.name).tag(Optional(option.id))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }
}
