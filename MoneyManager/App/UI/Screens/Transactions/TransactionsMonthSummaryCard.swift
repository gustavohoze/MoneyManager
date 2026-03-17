import SwiftUI

struct TransactionsMonthSummaryCard: View {
    let summary: TransactionMonthSummaryPresentation

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(summary.monthTitle)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text(summary.totalSpentText)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)

                Text(summary.transactionCountText)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.white)

                Text("Set Up Budget")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(14)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}
