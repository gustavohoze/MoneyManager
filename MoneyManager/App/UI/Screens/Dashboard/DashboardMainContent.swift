import SwiftUI

struct DashboardMainContent: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedWeeklyDayIndex: Int?
    @Binding var insightPage: Int
    var onSelectTransaction: (UUID) -> Void
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(spacing: 16) {
            DashboardFinancialStateCard(viewModel: viewModel, palette: palette)

            // Swipeable insight cards — one section at a time
            TabView(selection: $insightPage) {
                DashboardWeeklyTrendCard(
                    viewModel: viewModel,
                    selectedWeeklyDayIndex: $selectedWeeklyDayIndex,
                    insightPage: $insightPage,
                    palette: palette
                )
                    .padding(.horizontal, 4)
                    .tag(0)

                DashboardCategoryCard(
                    viewModel: viewModel,
                    insightPage: $insightPage,
                    palette: palette
                )
                    .padding(.horizontal, 4)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 252)
            .frame(maxWidth: .infinity)

            DashboardRecentTransactionsCard(
                viewModel: viewModel,
                palette: palette,
                onSelectTransaction: onSelectTransaction
            )
            .frame(maxWidth: .infinity)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .financeCard(palette: palette)
            }
        }
    }
}
