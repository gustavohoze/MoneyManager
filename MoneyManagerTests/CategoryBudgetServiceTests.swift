import Foundation
import Testing
@testable import MoneyManager

struct CategoryBudgetServiceTests {
    @Test("Test: specific-month budget overrides default budget")
    func resolvedBudgets_monthSpecificOverridesDefault() throws {
        let defaults = UserDefaults(suiteName: "CategoryBudgetServiceTests")
        defaults?.removePersistentDomain(forName: "CategoryBudgetServiceTests")
        let service = UserDefaultsCategoryBudgetService(
            defaults: defaults ?? .standard,
            storageKey: "category_budgets_test"
        )

        let calendar = Calendar(identifier: .iso8601)
        let monthStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? Date()

        try service.upsertBudget(category: "Food", amount: 500_000, monthStartDate: nil)
        try service.upsertBudget(category: "Food", amount: 400_000, monthStartDate: monthStart)
        try service.upsertBudget(category: "Transport", amount: 300_000, monthStartDate: nil)

        let resolved = service.resolvedBudgets(for: monthStart)

        let food = try #require(resolved.first(where: { $0.category == "Food" }))
        let transport = try #require(resolved.first(where: { $0.category == "Transport" }))

        #expect(food.amount == 400_000)
        #expect(food.source == .specificMonth)
        #expect(transport.amount == 300_000)
        #expect(transport.source == .defaultMonthly)
    }
}
