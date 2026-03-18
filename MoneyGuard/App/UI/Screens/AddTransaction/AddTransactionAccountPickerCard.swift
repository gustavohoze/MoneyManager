import SwiftUI

struct AddTransactionAccountPickerCard: View {
    var selectedAccount: TransactionFormAccountOption?
    let accounts: [TransactionFormAccountOption]
    let palette: FinanceTheme.Palette
    let onSelect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(palette.accent)

                Text(String(localized: "Method"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()
            }

            Menu {
                ForEach(accounts, id: \.id) { account in
                    Button {
                        onSelect(account.id)
                    } label: {
                        Text(account.name)
                    }
                }
            } label: {
                HStack {
                    if let selected = selectedAccount {
                        Text(selected.name)
                            .foregroundStyle(palette.ink)
                    } else {
                        Text(String(localized: "Select"))
                            .foregroundStyle(palette.secondaryInk)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.secondaryInk)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}
