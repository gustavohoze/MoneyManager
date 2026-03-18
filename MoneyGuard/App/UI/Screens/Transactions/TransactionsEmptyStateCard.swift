import SwiftUI

struct TransactionsEmptyStateCard: View {
    let title: String
    let message: String

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.accent)

            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)

            Text(message)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(palette.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }
}
