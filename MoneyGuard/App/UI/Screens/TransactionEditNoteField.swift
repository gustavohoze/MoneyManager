import SwiftUI

struct TransactionEditNoteField: View {
    @Binding var value: String
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Note"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
            TextField(String(localized: "Optional Note"), text: $value)
                .focused(focusedField, equals: .note)
        }
        .financeCard(palette: palette)
    }
}
