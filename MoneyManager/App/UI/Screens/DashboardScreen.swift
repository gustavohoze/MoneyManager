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
                DashboardMainContent(
                    viewModel: viewModel,
                    selectedWeeklyDayIndex: $selectedWeeklyDayIndex,
                    insightPage: $insightPage,
                    onSelectTransaction: onSelectTransaction,
                    palette: palette
                )
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
