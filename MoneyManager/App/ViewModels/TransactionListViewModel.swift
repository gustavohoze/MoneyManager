import Foundation
import Combine

private enum TransactionTimeBucket: CaseIterable {
    case morning
    case afternoon
    case evening
    case night

    var title: String {
        switch self {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        case .night:
            return "Night"
        }
    }

    func includes(_ hour: Int) -> Bool {
        switch self {
        case .morning:
            return (6..<12).contains(hour)
        case .afternoon:
            return (12..<18).contains(hour)
        case .evening:
            return (18..<24).contains(hour)
        case .night:
            return (0..<6).contains(hour)
        }
    }
}

struct TransactionMonthSummaryPresentation: Equatable {
    let monthTitle: String
    let totalSpentText: String
    let transactionCountText: String
}

struct TransactionYearMonthPresentation: Identifiable, Equatable {
    let id: Date
    let monthStartDate: Date
    let shortMonthLabel: String
    let totalSpentText: String
    let transactionCountText: String
    let lastVisitedText: String
    let isCurrentMonth: Bool
}

struct TransactionYearOverviewPresentation: Equatable {
    let year: Int
    let months: [TransactionYearMonthPresentation]
}

struct TransactionCalendarDayPresentation: Identifiable, Equatable {
    let id: Date
    let date: Date
    let weekdayLabel: String
    let dayNumberText: String
    let transactionCountText: String
    let isSelected: Bool
}

struct TransactionDaySummaryPresentation: Equatable {
    let title: String
    let subtitle: String
    let totalSpentText: String
    let transactionCountText: String
}

struct TransactionRowPresentation: Identifiable, Equatable {
    let id: UUID
    let merchant: String
    let categoryIcon: String
    let metaText: String
    let timeText: String
    let amountText: String
}

struct TransactionTimeGroupPresentation: Identifiable, Equatable {
    let id: String
    let title: String
    let totalSpentText: String
    let items: [TransactionRowPresentation]
}

struct TransactionCategoryBudgetPresentation: Identifiable, Equatable {
    let id: String
    let category: String
    let categoryIcon: String
    let spentValue: Double
    let limitValue: Double
    let remainingValue: Double
    let spentText: String
    let limitText: String
    let remainingText: String
    let isOverLimit: Bool
    let isDefault: Bool
}

struct TransactionMonthBudgetInsightPresentation: Equatable {
    let hasBudgets: Bool
    let budgetLeftText: String
    let totalBudgetText: String
    let achievedText: String

    static let empty = TransactionMonthBudgetInsightPresentation(
        hasBudgets: false,
        budgetLeftText: "-",
        totalBudgetText: "-",
        achievedText: "0/0 achieved"
    )
}

struct TransactionBudgetCategoryOption: Identifiable, Equatable {
    let name: String
    let icon: String

    var id: String {
        name
    }
}

struct TransactionTimelinePresentation: Equatable {
    let monthSummary: TransactionMonthSummaryPresentation
    let weekDays: [TransactionCalendarDayPresentation]
    let daySummary: TransactionDaySummaryPresentation
    let categoryFilters: [String]
    let selectedCategory: String
    let groups: [TransactionTimeGroupPresentation]
    let emptyStateTitle: String?
    let emptyStateMessage: String?

    static func empty(referenceDate: Date) -> TransactionTimelinePresentation {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"

        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "EEEE"

        let subtitleFormatter = DateFormatter()
        subtitleFormatter.dateFormat = "d MMMM yyyy"

        return TransactionTimelinePresentation(
            monthSummary: TransactionMonthSummaryPresentation(
                monthTitle: monthFormatter.string(from: referenceDate),
                totalSpentText: AppCurrency.formatted(0),
                transactionCountText: "0 transactions"
            ),
            weekDays: [],
            daySummary: TransactionDaySummaryPresentation(
                title: titleFormatter.string(from: referenceDate),
                subtitle: subtitleFormatter.string(from: referenceDate),
                totalSpentText: AppCurrency.formatted(0),
                transactionCountText: "0 transactions"
            ),
            categoryFilters: ["All"],
            selectedCategory: "All",
            groups: [],
            emptyStateTitle: "No transactions yet",
            emptyStateMessage: "Your transaction history will appear here once you add your first entry."
        )
    }
}

struct TransactionEditState: Identifiable, Equatable {
    var draft: TransactionEditDraft
    let options: TransactionFormOptions

    var id: UUID {
        draft.id
    }
}

@MainActor
final class TransactionListViewModel: ObservableObject {
    @Published private(set) var yearOverview: TransactionYearOverviewPresentation
    @Published private(set) var presentation: TransactionTimelinePresentation
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published private(set) var budgetSummary: [TransactionCategoryBudgetPresentation] = []
    @Published private(set) var monthBudgetInsight: TransactionMonthBudgetInsightPresentation = .empty
    @Published var editState: TransactionEditState?

    private let dataProvider: TransactionListDataProviding
    private let mutationService: TransactionMutating
    private let optionsProvider: TransactionFormOptionsProviding
    private let budgetProvider: CategoryBudgetProviding
    private let calendar = Calendar(identifier: .iso8601)
    private var allItems: [TransactionListItem] = []
    private var selectedDate: Date
    private var selectedCategory: String = "All"
    private var selectedYear: Int
    private var availableCategories: [TransactionFormCategoryOption] = []
    private var lastVisitedDateByMonthKey: [String: Date] = [:]
    private var didInitializeDate = false

    init(
        dataProvider: TransactionListDataProviding,
        mutationService: TransactionMutating = NoOpTransactionMutationService(),
        optionsProvider: TransactionFormOptionsProviding,
        budgetProvider: CategoryBudgetProviding = NoOpCategoryBudgetService()
    ) {
        self.dataProvider = dataProvider
        self.mutationService = mutationService
        self.optionsProvider = optionsProvider
        self.budgetProvider = budgetProvider
        self.selectedDate = Calendar(identifier: .iso8601).startOfDay(for: Date())
        self.selectedYear = Calendar(identifier: .iso8601).component(.year, from: Date())
        self.yearOverview = TransactionYearOverviewPresentation(year: Calendar(identifier: .iso8601).component(.year, from: Date()), months: [])
        self.presentation = TransactionTimelinePresentation.empty(referenceDate: Date())
    }

    func load(asOf date: Date = Date()) {
        let normalizedDate = calendar.startOfDay(for: date)
        if !didInitializeDate {
            selectedDate = normalizedDate
            selectedYear = calendar.component(.year, from: normalizedDate)
            didInitializeDate = true
        }

        rememberSelectedDateForMonth()

        do {
            allItems = try dataProvider.loadItems()
            availableCategories = (try? optionsProvider.loadOptions().categories.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }) ?? []
            refreshYearOverview()
            refreshPresentation()
            errorMessage = nil
        } catch {
            allItems = []
            availableCategories = []
            refreshYearOverview()
            presentation = TransactionTimelinePresentation.empty(referenceDate: selectedDate)
            budgetSummary = []
            monthBudgetInsight = .empty
            errorMessage = error.localizedDescription
        }
    }

    var budgetCategories: [String] {
        let categoryNames = availableCategories.map(\ .name)
        let base = categoryNames.isEmpty
            ? presentation.categoryFilters.filter { $0 != "All" }
            : categoryNames
        return Array(Set(base + budgetSummary.map(\ .category))).sorted()
    }

    var budgetCategoryOptions: [TransactionBudgetCategoryOption] {
        let iconByCategory = Dictionary(uniqueKeysWithValues: availableCategories.map { ($0.name, $0.icon) })
        let iconByItems = iconByCategoryForItems()
        return budgetCategories.map {
            TransactionBudgetCategoryOption(
                name: $0,
                icon: iconByCategory[$0] ?? iconByItems[$0] ?? "questionmark.circle"
            )
        }
    }

    func saveBudget(category: String, amount: Double, isDefault: Bool) {
        do {
            let monthStart = isDefault ? nil : selectedMonthStartDate()
            try budgetProvider.upsertBudget(category: category, amount: amount, monthStartDate: monthStart)
            actionMessage = "Budget saved."
            refreshPresentation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTransaction(id: UUID, asOf date: Date = .distantPast) {
        do {
            try mutationService.deleteTransaction(id: id)
            actionMessage = "Transaction deleted."
            if date != .distantPast {
                selectedDate = calendar.startOfDay(for: date)
            }
            load(asOf: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = nil
        }
    }

    func beginEdit(id: UUID) {
        do {
            let draft = try mutationService.loadEditDraft(id: id)
            let options = try optionsProvider.loadOptions()
            editState = TransactionEditState(draft: draft, options: options)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelEdit() {
        editState = nil
    }

    func saveEdit(draft: TransactionEditDraft, asOf date: Date = .distantPast) {
        do {
            try mutationService.updateTransaction(draft: draft)
            actionMessage = "Transaction updated."
            editState = nil
            if date != .distantPast {
                selectedDate = calendar.startOfDay(for: date)
            }
            load(asOf: selectedDate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        selectedYear = calendar.component(.year, from: selectedDate)
        rememberSelectedDateForMonth()
        refreshYearOverview()
        refreshPresentation()
    }

    func shiftWeek(by value: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: value * 7, to: selectedDate) else {
            return
        }

        selectedDate = calendar.startOfDay(for: newDate)
        selectedYear = calendar.component(.year, from: selectedDate)
        rememberSelectedDateForMonth()
        refreshYearOverview()
        refreshPresentation()
    }

    func selectCategory(_ category: String) {
        selectedCategory = category
        refreshPresentation()
    }

    func selectMonth(_ monthStartDate: Date) {
        if isCurrentMonth(monthStartDate) {
            selectedDate = calendar.startOfDay(for: Date())
        } else if let lastVisited = lastVisitedDateByMonthKey[monthKey(for: monthStartDate)] {
            selectedDate = calendar.startOfDay(for: lastVisited)
        } else {
            selectedDate = calendar.startOfDay(for: monthStartDate)
        }

        selectedYear = calendar.component(.year, from: selectedDate)
        rememberSelectedDateForMonth()
        refreshYearOverview()
        refreshPresentation()
    }

    func shiftYear(by value: Int) {
        selectedYear += value
        refreshYearOverview()
    }

    func currencyText(_ value: Double) -> String {
        AppCurrency.formatted(value)
    }

    private func refreshPresentation() {
        let monthItems = allItems.filter { calendar.isDate($0.date, equalTo: selectedDate, toGranularity: .month) }
        let categories = ["All"] + Array(Set(monthItems.map(\ .category))).sorted()

        if !categories.contains(selectedCategory) {
            selectedCategory = "All"
        }

        let filteredMonthItems = filterByCategory(monthItems)
        let filteredDayItems = filteredMonthItems.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
        let weekDates = makeWeekDates(containing: selectedDate)

        presentation = TransactionTimelinePresentation(
            monthSummary: makeMonthSummary(from: filteredMonthItems),
            weekDays: weekDates.map { makeCalendarDayPresentation(for: $0, monthItems: filteredMonthItems) },
            daySummary: makeDaySummary(from: filteredDayItems),
            categoryFilters: categories,
            selectedCategory: selectedCategory,
            groups: makeTimeGroups(from: filteredDayItems),
            emptyStateTitle: emptyStateTitle(allItems: allItems, filteredDayItems: filteredDayItems),
            emptyStateMessage: emptyStateMessage(allItems: allItems, filteredDayItems: filteredDayItems)
        )

        refreshBudgetSummary(monthItems: monthItems)
    }

    private func refreshYearOverview() {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"

        let visitedFormatter = DateFormatter()
        visitedFormatter.dateFormat = "d MMM"

        let months: [TransactionYearMonthPresentation] = (1...12).compactMap { monthValue in
            var components = DateComponents()
            components.calendar = calendar
            components.year = selectedYear
            components.month = monthValue
            components.day = 1

            guard let monthStartDate = calendar.date(from: components) else {
                return nil
            }

            let monthItems = allItems.filter {
                calendar.isDate($0.date, equalTo: monthStartDate, toGranularity: .month)
            }

            let lastVisitedDate = isCurrentMonth(monthStartDate)
                ? calendar.startOfDay(for: Date())
                : lastVisitedDateByMonthKey[monthKey(for: monthStartDate)]
            let lastVisitedText = lastVisitedDate.map {
                "Last: \(visitedFormatter.string(from: $0))"
            } ?? "Last: -"

            return TransactionYearMonthPresentation(
                id: monthStartDate,
                monthStartDate: monthStartDate,
                shortMonthLabel: monthFormatter.string(from: monthStartDate),
                totalSpentText: currencyText(monthItems.reduce(0) { $0 + $1.amount }),
                transactionCountText: transactionCountText(monthItems.count),
                lastVisitedText: lastVisitedText,
                isCurrentMonth: calendar.isDate(monthStartDate, equalTo: selectedDate, toGranularity: .month)
            )
        }

        yearOverview = TransactionYearOverviewPresentation(year: selectedYear, months: months)
    }

    private func filterByCategory(_ items: [TransactionListItem]) -> [TransactionListItem] {
        guard selectedCategory != "All" else {
            return items
        }

        return items.filter { $0.category == selectedCategory }
    }

    private func makeMonthSummary(from items: [TransactionListItem]) -> TransactionMonthSummaryPresentation {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "LLLL yyyy"

        return TransactionMonthSummaryPresentation(
            monthTitle: monthFormatter.string(from: selectedDate),
            totalSpentText: currencyText(items.reduce(0) { $0 + $1.amount }),
            transactionCountText: transactionCountText(items.count)
        )
    }

    private func makeCalendarDayPresentation(
        for date: Date,
        monthItems: [TransactionListItem]
    ) -> TransactionCalendarDayPresentation {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let dayItems = monthItems.filter { calendar.isDate($0.date, inSameDayAs: date) }

        return TransactionCalendarDayPresentation(
            id: date,
            date: date,
            weekdayLabel: dayFormatter.string(from: date),
            dayNumberText: String(calendar.component(.day, from: date)),
            transactionCountText: String(dayItems.count),
            isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
        )
    }

    private func makeDaySummary(from items: [TransactionListItem]) -> TransactionDaySummaryPresentation {
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "EEEE"

        let subtitleFormatter = DateFormatter()
        subtitleFormatter.dateFormat = "d MMMM yyyy"

        return TransactionDaySummaryPresentation(
            title: titleFormatter.string(from: selectedDate),
            subtitle: subtitleFormatter.string(from: selectedDate),
            totalSpentText: currencyText(items.reduce(0) { $0 + $1.amount }),
            transactionCountText: transactionCountText(items.count)
        )
    }

    private func makeTimeGroups(from items: [TransactionListItem]) -> [TransactionTimeGroupPresentation] {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        return TransactionTimeBucket.allCases.compactMap { bucket in
            let bucketItems = items.filter {
                bucket.includes(calendar.component(.hour, from: $0.date))
            }

            guard !bucketItems.isEmpty else {
                return nil
            }

            return TransactionTimeGroupPresentation(
                id: bucket.title,
                title: bucket.title,
                totalSpentText: currencyText(bucketItems.reduce(0) { $0 + $1.amount }),
                items: bucketItems.map {
                    TransactionRowPresentation(
                        id: $0.id,
                        merchant: $0.merchant,
                        categoryIcon: $0.categoryIcon,
                        metaText: "\($0.category) • \($0.account)",
                        timeText: timeFormatter.string(from: $0.date),
                        amountText: currencyText($0.amount)
                    )
                }
            )
        }
    }

    private func makeWeekDates(containing date: Date) -> [Date] {
        let normalizedDate = calendar.startOfDay(for: date)
        let day = calendar.component(.day, from: normalizedDate)
        // Month-aligned windows: 1–7, 8–14, 15–21, 22–28, 29–31
        let windowStartDay = ((day - 1) / 7) * 7 + 1
        var components = calendar.dateComponents([.year, .month], from: normalizedDate)
        components.day = windowStartDay
        guard let windowStart = calendar.date(from: components) else {
            return [normalizedDate]
        }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: windowStart)
        }
    }

    private func refreshBudgetSummary(monthItems: [TransactionListItem]) {
        let monthStart = selectedMonthStartDate()
        let resolvedBudgets = budgetProvider.resolvedBudgets(for: monthStart)
        let itemIconByCategory = iconByCategoryForItems()
        let optionIconByCategory = Dictionary(
            availableCategories.map { ($0.name, $0.icon) },
            uniquingKeysWith: { first, _ in first }
        )
        budgetSummary = resolvedBudgets.map { budget in
            let spent = monthItems
                .filter { $0.category == budget.category }
                .reduce(0) { $0 + $1.amount }
            let remaining = budget.amount - spent
            return TransactionCategoryBudgetPresentation(
                id: budget.category,
                category: budget.category,
                categoryIcon: optionIconByCategory[budget.category] ?? itemIconByCategory[budget.category] ?? "questionmark.circle",
                spentValue: spent,
                limitValue: budget.amount,
                remainingValue: remaining,
                spentText: currencyText(spent),
                limitText: currencyText(budget.amount),
                remainingText: remaining >= 0 ? "Left: \(currencyText(remaining))" : "Over: \(currencyText(abs(remaining)))",
                isOverLimit: remaining < 0,
                isDefault: budget.source == .defaultMonthly
            )
        }
        .sorted { $0.category < $1.category }

        let totalLimit = budgetSummary.reduce(0) { $0 + $1.limitValue }
        let totalRemaining = budgetSummary.reduce(0) { $0 + $1.remainingValue }
        let achievedCount = budgetSummary.filter { !$0.isOverLimit }.count
        monthBudgetInsight = TransactionMonthBudgetInsightPresentation(
            hasBudgets: !budgetSummary.isEmpty,
            budgetLeftText: currencyText(max(totalRemaining, 0)),
            totalBudgetText: currencyText(totalLimit),
            achievedText: "\(achievedCount)/\(budgetSummary.count) achieved"
        )
    }

    private func selectedMonthStartDate() -> Date {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        return calendar.date(from: DateComponents(year: components.year, month: components.month, day: 1))
            ?? calendar.startOfDay(for: selectedDate)
    }

    private func iconByCategoryForItems() -> [String: String] {
        allItems.reduce(into: [String: String]()) { partialResult, item in
            partialResult[item.category] = item.categoryIcon
        }
    }

    private func totalSpent(on date: Date, within items: [TransactionListItem]) -> Double {
        items
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.amount }
    }

    private func transactionCountText(_ count: Int) -> String {
        count == 1 ? "1 transaction" : "\(count) transactions"
    }

    private func rememberSelectedDateForMonth() {
        lastVisitedDateByMonthKey[monthKey(for: selectedDate)] = calendar.startOfDay(for: selectedDate)
    }

    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    private func emptyStateTitle(allItems: [TransactionListItem], filteredDayItems: [TransactionListItem]) -> String? {
        if allItems.isEmpty {
            return "No transactions yet"
        }

        return filteredDayItems.isEmpty ? "No activity on this day" : nil
    }

    private func emptyStateMessage(allItems: [TransactionListItem], filteredDayItems: [TransactionListItem]) -> String? {
        if allItems.isEmpty {
            return "Your transaction history will appear here once you add your first entry."
        }

        guard filteredDayItems.isEmpty else {
            return nil
        }

        if selectedCategory == "All" {
            return "Pick another date in the week strip to jump across your recent spending."
        }

        return "There are no \(selectedCategory.lowercased()) transactions on this date."
    }
}
