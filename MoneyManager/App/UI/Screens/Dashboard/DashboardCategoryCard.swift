import SwiftUI

struct DashboardCategoryCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var insightPage: Int
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Category Distribution"))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                DashboardInsightPageIndicator(insightPage: $insightPage, palette: palette)
            }

            if viewModel.shouldShowCategoryPrompt {
                Text(String(localized: "Categorize transactions to see spending insights."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.ink)

                Text(
                    "\(viewModel.uncategorizedCountEstimate(recentCount: viewModel.recentTransactions.count)) "
                    + String(localized: "transactions need categories.")
                )
                .font(.footnote)
                .foregroundStyle(palette.secondaryInk)
            } else {
                ForEach(Array(viewModel.categoryRows.prefix(3).enumerated()), id: \.offset) { _, row in
                    VStack(spacing: 4) {
                        HStack {
                            Text(row.category)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Spacer()
                            Text(viewModel.currencyText(row.total))
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(palette.ink)
                        }

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
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .financeCard(palette: palette)
    }
}
