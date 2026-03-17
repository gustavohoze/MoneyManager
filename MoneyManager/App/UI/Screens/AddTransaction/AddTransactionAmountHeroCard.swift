import SwiftUI

struct AddTransactionAmountHeroCard: View {
    @Binding var amountText: String
    var fontSize: Double
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    var palette: FinanceTheme.Palette
    var onAmountChange: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Amount"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: 8) {
                Text("Rp")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                TextField("0", text: $amountText)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .tint(palette.accent)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .amount)
                    .onChange(of: amountText) { _, newValue in
                        onAmountChange(newValue)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
