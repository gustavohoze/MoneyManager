import SwiftUI

struct TransactionListScreen: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var path: [Date] = []

    var body: some View {
        NavigationStack(path: $path) {
            TransactionsYearOverviewPage(
                overview: viewModel.yearOverview,
                onShiftYear: viewModel.shiftYear,
                onSelectMonth: { monthStartDate in
                    viewModel.selectMonth(monthStartDate)
                    path.append(monthStartDate)
                }
            )
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Transactions"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear() {
                viewModel.load()
            }
            .navigationDestination(for: Date.self) { _ in
                TransactionsTimelineDetailPage(viewModel: viewModel)
                    .background(FinanceTheme.pageBackground(for: colorScheme))
            }
        }
    }
}
