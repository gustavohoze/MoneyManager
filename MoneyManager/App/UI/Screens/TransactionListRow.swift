import SwiftUI

struct TransactionListRow: View {
    let item: TransactionListItem
    let palette: FinanceTheme.Palette
    let amountText: String
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "creditcard")
                .foregroundStyle(palette.accent)
                .frame(width: 30, height: 30)
                .background(palette.accentSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.merchant)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text("\(item.category) • \(item.account)")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryInk)
            }
            Spacer()
            Text(amountText)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
        }
        .financeCard(palette: palette)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label(String(localized: "Delete"), systemImage: "trash")
            }
        }
    }
}
