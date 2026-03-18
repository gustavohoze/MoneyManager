import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isEarned: Bool
    let earnedDate: Date?
    let redeemCode: String?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        isEarned: Bool = false,
        earnedDate: Date? = nil,
        redeemCode: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isEarned = isEarned
        self.earnedDate = earnedDate
        self.redeemCode = redeemCode
    }
}

enum AchievementType {
    static let allAchievements: [Achievement] = [
        Achievement(
            id: "streak_7",
            title: String(localized: "Week Warrior"),
            description: String(localized: "Maintain a 7-day check-in streak"),
            icon: "flame.fill"
        ),
        Achievement(
            id: "streak_30",
            title: String(localized: "Month Master"),
            description: String(localized: "Maintain a 30-day check-in streak"),
            icon: "star.fill"
        ),
        Achievement(
            id: "first_budget",
            title: String(localized: "Budget Setter"),
            description: String(localized: "Create your first budget"),
            icon: "chart.pie.fill"
        ),
        Achievement(
            id: "milestone_balance",
            title: String(localized: "Saver"),
            description: String(localized: "Reach a balance milestone"),
            icon: "banknote.fill"
        ),
        Achievement(
            id: "zero_uncategorized",
            title: String(localized: "Organizer"),
            description: String(localized: "Categorize all transactions"),
            icon: "checkmark.circle.fill"
        ),
        Achievement(
            id: "first_transaction",
            title: String(localized: "First Step"),
            description: String(localized: "Log your first transaction"),
            icon: "arrow.up.right.circle.fill"
        ),
    ]
}
