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
                VStack(spacing: 10) {
                    let topCategories = Array(viewModel.categoryRows.prefix(3))
                    let maxCategoryTotal = topCategories.map { $0.total }.max() ?? 1
                    
                    ForEach(Array(topCategories.enumerated()), id: \.offset) { _, row in
                        VStack(spacing: 5) {
                            HStack {
                                Text(row.category)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)
                                    .lineLimit(1)
                                Spacer()
                                Text(maskedCurrencyText(row.total))
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(palette.ink)
                                    .onTapGesture {
                                        if shouldMaskBalances {
                                            onRevealBalances()
                                        }
                                    }
                            }
                            .frame(height: 20)

                            GeometryReader { proxy in
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(palette.accentSoft)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(palette.accent)
                                            .frame(width: max(0, proxy.size.width * (row.total / maxCategoryTotal)))
                                    }
                            }
                            .frame(height: 8)
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 38, alignment: .top)
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
