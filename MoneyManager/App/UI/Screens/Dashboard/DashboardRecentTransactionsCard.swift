import SwiftUI

struct DashboardRecentTransactionsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let palette: FinanceTheme.Palette
    let onSelectTransaction: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Recent Transactions"))
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)

            if viewModel.recentTransactions.isEmpty {
                Text(String(localized: "No transactions yet"))
                    .foregroundStyle(palette.secondaryInk)
            } else {
                let rows = Array(viewModel.recentTransactions.enumerated())
                ForEach(rows, id: \.offset) { index, item in
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: item.categoryIcon)
                                .foregroundStyle(palette.accent)
                                .frame(width: 30, height: 30)
                                .background(palette.accentSoft)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.merchant)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)

                                Text("\(item.category) • \(item.account) • \(viewModel.relativeTimeText(from: item.date))")
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryInk)
                            }

                            Spacer()

                            Text(viewModel.currencyText(item.amount))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(palette.secondaryInk)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectTransaction(item.id)
                        }

                        if index < rows.count - 1 {
                            Divider()
                                .overlay(palette.accentSoft)
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .financeCard(palette: palette)
    }
}
