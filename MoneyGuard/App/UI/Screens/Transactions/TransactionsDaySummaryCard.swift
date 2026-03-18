import SwiftUI

struct TransactionsDaySummaryCard: View {
    let summary: TransactionDaySummaryPresentation
    var showsContainer: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.ink)

                Text(summary.subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(summary.totalSpentText)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.ink)

                Text(summary.transactionCountText)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            }
        }
        .modifier(ConditionalFinanceCardModifier(enabled: showsContainer, palette: palette))
    }
}

private struct ConditionalFinanceCardModifier: ViewModifier {
    let enabled: Bool
    let palette: FinanceTheme.Palette

    func body(content: Content) -> some View {
        if enabled {
            content.financeCard(palette: palette)
        } else {
            content
        }
    }
}
