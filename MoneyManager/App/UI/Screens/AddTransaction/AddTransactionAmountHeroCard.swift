import SwiftUI

struct AddTransactionAmountHeroCard: View {
    @Binding var amountText: String
    var currencyCode: String
    var fontSize: Double
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    var palette: FinanceTheme.Palette
    var onAmountChange: (String) -> Void

    private var isAmountFocused: Bool {
        focusedField.wrappedValue == .amount
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text(String(localized: "Amount"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isAmountFocused {
                    Button(String(localized: "Done")) {
                        focusedField.wrappedValue = nil
                    }
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.heroEnd)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.92), in: Capsule())
                }
            }

            HStack(alignment: .center, spacing: 8) {
                Text(AppCurrency.symbol(for: currencyCode))
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
