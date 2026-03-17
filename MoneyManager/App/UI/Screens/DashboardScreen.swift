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
                    financialStateCard

                    // Swipeable insight cards — one section at a time
                    TabView(selection: $insightPage) {
                        weeklyTrendCard
                            .padding(.horizontal, 4)
                            .tag(0)

                        categoryCard
                            .padding(.horizontal, 4)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 252)
                    .frame(maxWidth: .infinity)

                    recentTransactionsCard

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
                    selectedWeeklyDayIndex = defaultWeeklyDayIndex
                }
                viewModel.load()
            }
        }
    }

    private var financialStateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Financial State"))
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Text(currencyText(viewModel.currentBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(String(localized: "Available balance"))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))

            Divider()
                .overlay(.white.opacity(0.3))

            HStack(spacing: 12) {
                metricPill(
                    title: String(localized: "After Bills"),
                    value: currencyText(viewModel.afterBillsBalance)
                )
                metricPill(
                    title: String(localized: "Safe Daily"),
                    value: currencyText(viewModel.safeDailySpend)
                )
            }

            Text(String(localized: "Income in \(viewModel.daysUntilIncome) days"))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: palette.accent.opacity(0.35), radius: 14, x: 0, y: 8)
    }

    private var weeklyTrendCard: some View {
        let selectedIndex = selectedWeeklyDayIndex ?? defaultWeeklyDayIndex
        let selectedAmount = (0..<viewModel.weekDailySpending.count).contains(selectedIndex)
            ? viewModel.weekDailySpending[selectedIndex]
            : 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(weekdayLabel(for: selectedIndex))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)

                Spacer()

                insightPageIndicator
            }

            Text(currencyText(selectedAmount))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(palette.ink)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(viewModel.weekDailySpending.enumerated()), id: \.offset) { index, amount in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill((selectedWeeklyDayIndex == index ? palette.heroEnd : palette.accent).opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: barHeight(for: amount))
                            .onTapGesture {
                                selectedWeeklyDayIndex = index
                            }

                        Text(weekdayLabel(for: index))
                            .font(.caption2)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
            }
            .frame(height: 60)

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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .financeCard(palette: palette)
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(localized: "Category Distribution"))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()

                insightPageIndicator
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
                            Text(currencyText(row.total))
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

    private var insightPageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(insightPage == index ? palette.accent : palette.accentSoft)
                    .frame(width: insightPage == index ? 20 : 8, height: 6)
                    .animation(.spring(response: 0.25, dampingFraction: 0.85), value: insightPage)
                    .onTapGesture {
                        insightPage = index
                    }
                    .accessibilityLabel(index == 0 ? "Weekly Trend" : "Category Distribution")
                    .accessibilityAddTraits(insightPage == index ? [.isSelected] : [])
            }
        }
    }

    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Recent Transactions"))
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)

            if viewModel.recentTransactions.isEmpty {
                Text(String(localized: "No transactions yet"))
                    .foregroundStyle(palette.secondaryInk)
            } else {
                let rows = Array(viewModel.recentTransactions.enumerated())
                ForEach(rows, id: \.offset) { index, item in
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: item.categoryIcon)
                                .foregroundStyle(palette.accent)
                                .frame(width: 30, height: 30)
                                .background(palette.accentSoft)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.merchant)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)

                                Text("\(item.category) • \(item.account) • \(relativeTime(from: item.date))")
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryInk)
                            }

                            Spacer()

                            Text(currencyText(item.amount))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(palette.secondaryInk)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectTransaction(item.id)
                        }

                        if index < rows.count - 1 {
                            Divider()
                                .overlay(palette.accentSoft)
                                .padding(.leading, 40)
                        }
                    }
                }
            }
        }
        .financeCard(palette: palette)
    }

    private func metricPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(palette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(palette.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func currencyText(_ value: Double) -> String {
        value.formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }

    private func relativeTime(from date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func barHeight(for amount: Double) -> CGFloat {
        let maxValue = viewModel.weekDailySpending.max() ?? 0
        guard maxValue > 0 else { return 8 }
        return max(8, CGFloat(amount / maxValue) * 56)
    }

    private var defaultWeeklyDayIndex: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        switch weekday {
        case 2...7:
            return weekday - 2 // Monday → 0
        case 1:
            return 6 // Sunday → last index
        default:
            return 0
        }
    }

    private func weekdayLabel(for index: Int) -> String {
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        guard (0..<labels.count).contains(index) else {
            return "-"
        }
        return labels[index]
    }
}
