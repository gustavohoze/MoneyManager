import SwiftUI

struct TransactionsTimelineDetailPage: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var toast: UniversalToastState?

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Month summary hero card with budget navigation
                NavigationLink {
                    TransactionsSetupBudgetPage(viewModel: viewModel)
                } label: {
                    TransactionsMonthSummaryCard(summary: viewModel.presentation.monthSummary)
                }
                .buttonStyle(.plain)

                // Week calendar
                TransactionsWeekCalendarStrip(
                    title: viewModel.presentation.monthSummary.monthTitle,
                    days: viewModel.presentation.weekDays,
                    onSelectDate: viewModel.selectDate,
                    onShiftWeek: viewModel.shiftWeek
                )

                // Unified detail container: Day summary -> Filter -> Time groups
                VStack(alignment: .leading, spacing: 12) {
                    TransactionsDaySummaryCard(summary: viewModel.presentation.daySummary, showsContainer: false)

                    if viewModel.presentation.categoryFilters.count > 1 {
                        TransactionsFilterBar(
                            filters: viewModel.presentation.categoryFilters,
                            selectedFilter: viewModel.presentation.selectedCategory,
                            onSelectFilter: viewModel.selectCategory
                        )
                    }

                    Divider()

                    if let emptyTitle = viewModel.presentation.emptyStateTitle,
                       let emptyMessage = viewModel.presentation.emptyStateMessage,
                       viewModel.presentation.groups.isEmpty {
                        TransactionsEmptyStateCard(
                            title: emptyTitle,
                            message: emptyMessage
                        )
                    } else {
                        transactionListLayout
                    }
                }
                .financeCard(palette: palette)

            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .navigationTitle(String(localized: "Transactions"))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: viewModel.presentation)
        .overlay(alignment: .bottom) {
            if let toast {
                UniversalToastView(
                    state: toast,
                    palette: palette,
                    onUndo: nil,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            self.toast = nil
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: toast?.id)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = nil
            }
        }
        .onChange(of: viewModel.toastEventID) { _, _ in
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                withAnimation(.easeInOut(duration: 0.22)) {
                    toast = UniversalToastState(message: errorMessage, isError: true)
                }
                return
            }

            if let actionMessage = viewModel.actionMessage, !actionMessage.isEmpty {
                withAnimation(.easeInOut(duration: 0.22)) {
                    toast = UniversalToastState(message: actionMessage)
                }
            }
        }
    }

    private var transactionListLayout: some View {
        VStack(spacing: 12) {
            if !combinedMorningNightGroups.isEmpty {
                TransactionsTimelineGroupCard(
                    groups: combinedMorningNightGroups,
                    onEdit: viewModel.beginEdit,
                    onDelete: { viewModel.deleteTransaction(id: $0) },
                    showsContainer: false
                )
            }

            ForEach(remainingGroups) { group in
                TransactionsTimelineGroupCard(
                    groups: [group],
                    onEdit: viewModel.beginEdit,
                    onDelete: { viewModel.deleteTransaction(id: $0) },
                    showsContainer: false
                )
            }
        }
    }

    private var combinedMorningNightGroups: [TransactionTimeGroupPresentation] {
        viewModel.presentation.groups.filter {
            let title = $0.title.lowercased()
            return (title.contains("morning") || title.contains("night")) && !title.contains("afternoon")
        }
    }

    private var remainingGroups: [TransactionTimeGroupPresentation] {
        viewModel.presentation.groups.filter {
            let title = $0.title.lowercased()
            return !title.contains("morning") && !title.contains("night")
        }
    }
}
