import Foundation

struct ResolvedCategoryBudget: Equatable {
    let category: String
    let amount: Double
    let source: CategoryBudgetSource
}

protocol CategoryBudgetProviding {
    func upsertBudget(category: String, amount: Double, monthStartDate: Date?) throws
    func deleteBudget(category: String, monthStartDate: Date?) throws
    func resolvedBudgets(for monthStartDate: Date) -> [ResolvedCategoryBudget]
}

private struct StoredCategoryBudget: Codable, Equatable {
    let category: String
    let amount: Double
    let monthKey: String?
}

struct NoOpCategoryBudgetService: CategoryBudgetProviding {
    func upsertBudget(category: String, amount: Double, monthStartDate: Date?) throws {}

    func deleteBudget(category: String, monthStartDate: Date?) throws {}

    func resolvedBudgets(for monthStartDate: Date) -> [ResolvedCategoryBudget] {
        []
    }
}

final class UserDefaultsCategoryBudgetService: CategoryBudgetProviding {
    private let defaults: UserDefaults
    private let storageKey: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let calendar = Calendar(identifier: .iso8601)

    init(defaults: UserDefaults = .standard, storageKey: String = "category_budgets_v1") {
        self.defaults = defaults
        self.storageKey = storageKey
    }

    func upsertBudget(category: String, amount: Double, monthStartDate: Date?) throws {
        guard amount > 0 else {
            return
        }

        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCategory.isEmpty else {
            return
        }

        let key = monthStartDate.map(monthKey(for:))
        var existing = loadStoredBudgets()
        existing.removeAll { $0.category == normalizedCategory && $0.monthKey == key }
        existing.append(StoredCategoryBudget(category: normalizedCategory, amount: amount, monthKey: key))
        let data = try encoder.encode(existing)
        defaults.set(data, forKey: storageKey)
    }

    func deleteBudget(category: String, monthStartDate: Date?) throws {
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCategory.isEmpty else {
            return
        }

        let key = monthStartDate.map(monthKey(for:))
        var existing = loadStoredBudgets()
        existing.removeAll { $0.category == normalizedCategory && $0.monthKey == key }
        let data = try encoder.encode(existing)
        defaults.set(data, forKey: storageKey)
    }

    func resolvedBudgets(for monthStartDate: Date) -> [ResolvedCategoryBudget] {
        let monthKey = monthKey(for: monthStartDate)
        let stored = loadStoredBudgets()

        var resolved: [String: ResolvedCategoryBudget] = [:]

        for item in stored where item.monthKey == nil {
            resolved[item.category] = ResolvedCategoryBudget(
                category: item.category,
                amount: item.amount,
                source: .defaultMonthly
            )
        }

        for item in stored where item.monthKey == monthKey {
            resolved[item.category] = ResolvedCategoryBudget(
                category: item.category,
                amount: item.amount,
                source: .specificMonth
            )
        }

        return resolved.values.sorted { $0.category < $1.category }
    }

    private func loadStoredBudgets() -> [StoredCategoryBudget] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        return (try? decoder.decode([StoredCategoryBudget].self, from: data)) ?? []
    }

    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
}
