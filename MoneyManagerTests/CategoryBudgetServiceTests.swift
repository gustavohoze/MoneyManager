import Foundation
import Testing
@testable import Money_Guard

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

    @Test("Test: delete budget removes only targeted scope")
    func deleteBudget_removesOnlyMatchingDefaultOrMonthEntry() throws {
        let defaults = UserDefaults(suiteName: "CategoryBudgetServiceDeleteTests")
        defaults?.removePersistentDomain(forName: "CategoryBudgetServiceDeleteTests")
        let service = UserDefaultsCategoryBudgetService(
            defaults: defaults ?? .standard,
            storageKey: "category_budgets_delete_test"
        )

        let calendar = Calendar(identifier: .iso8601)
        let monthStart = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1)) ?? Date()

        try service.upsertBudget(category: "Food", amount: 500_000, monthStartDate: nil)
        try service.upsertBudget(category: "Food", amount: 400_000, monthStartDate: monthStart)

        try service.deleteBudget(category: "Food", monthStartDate: monthStart)

        let resolvedAfterMonthDelete = service.resolvedBudgets(for: monthStart)
        let remainingFood = try #require(resolvedAfterMonthDelete.first(where: { $0.category == "Food" }))
        #expect(remainingFood.amount == 500_000)
        #expect(remainingFood.source == .defaultMonthly)

        try service.deleteBudget(category: "Food", monthStartDate: nil)

        let resolvedAfterDefaultDelete = service.resolvedBudgets(for: monthStart)
        #expect(resolvedAfterDefaultDelete.first(where: { $0.category == "Food" }) == nil)
    }
}
