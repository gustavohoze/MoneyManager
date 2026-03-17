import SwiftUI

struct TransactionsTimelineDetailPage: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTimeGroup: String? = nil

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

                // Day summary and filters
                VStack(alignment: .leading, spacing: 12) {
                    TransactionsDaySummaryCard(summary: viewModel.presentation.daySummary, showsContainer: true)

                    if viewModel.presentation.categoryFilters.count > 1 {
                        TransactionsFilterBar(
                            filters: viewModel.presentation.categoryFilters,
                            selectedFilter: viewModel.presentation.selectedCategory,
                            onSelectFilter: viewModel.selectCategory
                        )
                    }
                }

                // Time-based grid tiles or list
                if let emptyTitle = viewModel.presentation.emptyStateTitle,
                   let emptyMessage = viewModel.presentation.emptyStateMessage,
                   viewModel.presentation.groups.isEmpty {
                    TransactionsEmptyStateCard(
                        title: emptyTitle,
                        message: emptyMessage
                    )
                } else if shouldShowGridLayout {
                    transactionGridLayout
                } else {
                    transactionListLayout
                }

                if let actionMessage = viewModel.actionMessage {
                    TransactionsInlineMessageCard(
                        title: String(localized: "Last Action"),
                        message: actionMessage,
                        color: .green
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    TransactionsInlineMessageCard(
                        title: String(localized: "Error"),
                        message: errorMessage,
                        color: .red
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .navigationTitle(String(localized: "Transactions"))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: viewModel.presentation)
    }

    private var shouldShowGridLayout: Bool {
        combinedMorningNightGroups.count + remainingGroups.count <= 4
    }

    private var transactionGridLayout: some View {
        VStack(spacing: 12) {
            // Create 2-column grid
            let allGroups = combinedMorningNightGroups + remainingGroups
            let rows = (allGroups.count + 1) / 2

            ForEach(0..<rows, id: \.self) { rowIndex in
                HStack(spacing: 12) {
                    let leftIndex = rowIndex * 2
                    if leftIndex < allGroups.count {
                        TransactionTimeGroupTile(
                            group: allGroups[leftIndex],
                            palette: palette,
                            onEdit: viewModel.beginEdit,
                            onDelete: { viewModel.deleteTransaction(id: $0) }
                        )
                    }

                    let rightIndex = rowIndex * 2 + 1
                    if rightIndex < allGroups.count {
                        TransactionTimeGroupTile(
                            group: allGroups[rightIndex],
                            palette: palette,
                            onEdit: viewModel.beginEdit,
                            onDelete: { viewModel.deleteTransaction(id: $0) }
                        )
                    } else {
                        Color.clear
                            .frame(minHeight: 120)
                    }
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
                    showsContainer: true
                )
            }

            ForEach(remainingGroups) { group in
                TransactionsTimelineGroupCard(
                    groups: [group],
                    onEdit: viewModel.beginEdit,
                    onDelete: { viewModel.deleteTransaction(id: $0) },
                    showsContainer: true
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

struct TransactionTimeGroupTile: View {
    let group: TransactionTimeGroupPresentation
    let palette: FinanceTheme.Palette
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    @State private var expandedTransactionId: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                // Icon based on time group
                Image(systemName: timeIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(palette.accent)
                    .frame(width: 28, height: 28)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(group.title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text("\(group.items.count) transaction\(group.items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                Text(group.totalSpentText)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.accent)
            }

            // Transactions preview (show first 2, then count)
            VStack(spacing: 6) {
                ForEach(Array(group.items.prefix(2)), id: \.id) { transaction in
                    HStack(spacing: 8) {
                        Image(systemName: transaction.categoryIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(palette.secondaryInk)
                            .frame(width: 16)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(transaction.merchant)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(palette.ink)
                                .lineLimit(1)

                            Text(transaction.metaText)
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundStyle(palette.secondaryInk)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text(transaction.amountText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(palette.accent)
                    }
                }

                if group.items.count > 2 {
                    Text("+\(group.items.count - 2) more")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(palette.secondaryInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }

    private var timeIcon: String {
        let title = group.title.lowercased()
        if title.contains("morning") {
            return "sunrise.fill"
        } else if title.contains("afternoon") {
            return "sun.max.fill"
        } else if title.contains("night") {
            return "moon.stars.fill"
        } else {
            return "clock.fill"
        }
    }
}
