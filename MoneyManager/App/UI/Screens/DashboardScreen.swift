import SwiftUI

struct DashboardScreen: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onSelectTransaction: (UUID) -> Void = { _ in }
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedWeeklyDayIndex: Int?
    @State private var insightPage: Int = 0

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
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

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .financeCard(palette: palette)
                    }
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Dashboard"))
            .onAppear {
                if selectedWeeklyDayIndex == nil {
                    selectedWeeklyDayIndex = viewModel.defaultWeeklyDayIndex()
                }
                viewModel.load()
            }
        }
    }
}
