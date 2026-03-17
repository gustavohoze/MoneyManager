import SwiftUI

struct SettingsAccountRow: View {
    let paymentMethod: PaymentMethodListItem
    let palette: FinanceTheme.Palette
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.pass")
                .foregroundStyle(palette.accent)
                .frame(width: 30, height: 30)
                .background(palette.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(paymentMethod.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)
                Text("\(paymentMethod.type.capitalized) • \(paymentMethod.currency)")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryInk)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .financeCard(palette: palette)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
