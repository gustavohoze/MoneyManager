import SwiftUI

struct DashboardFinancialStateCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Financial State"))
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Text(viewModel.currencyText(viewModel.currentBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(String(localized: "Available balance"))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))

            Divider()
                .overlay(.white.opacity(0.3))

            HStack(spacing: 12) {
                DashboardMetricPill(
                    title: String(localized: "Projected"),
                    value: viewModel.currencyText(viewModel.afterBillsBalance)
                )
                DashboardMetricPill(
                    title: String(localized: "Safe Daily"),
                    value: viewModel.currencyText(viewModel.safeDailySpend)
                )
            }

            Text(String(localized: "Cycle resets in \(viewModel.daysRemainingInCycle) days"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: palette.accent.opacity(0.35), radius: 14, x: 0, y: 8)
    }
}
