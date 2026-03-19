import SwiftUI

struct DashboardCategoryCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var insightPage: Int
    let shouldMaskBalances: Bool
    let onRevealBalances: () -> Void
    let palette: FinanceTheme.Palette

    private func maskedCurrencyText(_ value: Double) -> String {
        shouldMaskBalances ? "••••••" : viewModel.currencyText(value)
    }

    private var hasTransactions: Bool {
        !viewModel.recentTransactions.isEmpty
    }

    var body: some View {
        VStack(alignment: viewModel.shouldShowCategoryPrompt ? .center : .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Category Distribution"))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                DashboardInsightPageIndicator(insightPage: $insightPage, palette: palette)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.shouldShowCategoryPrompt {
                VStack(spacing: 6) {
                    Text(String(localized: "Categorize transactions to see spending insights."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.ink)
                        .multilineTextAlignment(.center)

                    Text(
                        "\(viewModel.uncategorizedCountEstimate(recentCount: viewModel.recentTransactions.count)) "
                        + String(localized: "transactions need categories.")
                    )
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryInk)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.categoryRows.enumerated()), id: \.offset) { _, row in
                        VStack(spacing: 4) {
                            HStack {
                                Text(row.category)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(palette.ink)
                                    .lineLimit(1)
                                Spacer()
                                Text(maskedCurrencyText(row.total))
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(palette.ink)
                                    .onTapGesture {
                                        if shouldMaskBalances {
                                            onRevealBalances()
                                        }
                                    }
                            }
                            .frame(height: 18)

                            GeometryReader { proxy in
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(palette.accentSoft)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(palette.accent)
                                            .frame(width: max(0, proxy.size.width * viewModel.categoryBarRatio(for: row)))
                                    }
                            }
                            .frame(height: 7)
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 29, alignment: .top)
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }
}
