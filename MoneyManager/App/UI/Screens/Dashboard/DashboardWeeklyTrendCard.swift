import SwiftUI

struct DashboardWeeklyTrendCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedWeeklyDayIndex: Int?
    @Binding var insightPage: Int
    let palette: FinanceTheme.Palette

    private var hasTransactions: Bool {
        !viewModel.recentTransactions.isEmpty
    }

    var body: some View {
        let selectedIndex = selectedWeeklyDayIndex ?? viewModel.defaultWeeklyDayIndex()
        let selectedAmount = (0..<viewModel.weekDailySpending.count).contains(selectedIndex)
            ? viewModel.weekDailySpending[selectedIndex]
            : 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(hasTransactions ? viewModel.weekdayLabel(for: selectedIndex) : String(localized: "Weekly Trend"))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)

                Spacer()

                DashboardInsightPageIndicator(insightPage: $insightPage, palette: palette)
            }

            if hasTransactions {
                Text(viewModel.currencyText(selectedAmount))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.ink)

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(viewModel.weekDailySpending.enumerated()), id: \.offset) { index, amount in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill((selectedWeeklyDayIndex == index ? palette.heroEnd : palette.accent).opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .frame(height: viewModel.weeklyBarHeight(for: amount))
                                .onTapGesture {
                                    selectedWeeklyDayIndex = index
                                }

                            Text(viewModel.weekdayLabel(for: index))
                                .font(.caption2)
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }
                }
                .frame(height: 50)

                if !viewModel.derivedAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.derivedAlerts.enumerated()), id: \.offset) { _, alert in
                            let tone = viewModel.alertTone(for: alert)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(alert.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(tone.title)
                                Text(alert.detail)
                                    .font(.footnote)
                                    .foregroundStyle(tone.detail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(tone.background)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text(String(localized: "No transactions yet"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text(String(localized: "Add your first transaction to unlock weekly trends."))
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryInk)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .financeCard(palette: palette)
    }
}
