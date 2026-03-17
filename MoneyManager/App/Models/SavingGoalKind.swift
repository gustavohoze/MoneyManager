import Foundation

enum SavingGoalKind: String, CaseIterable, Identifiable {
    case shopping
    case vacation
    case anything

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shopping:
            return String(localized: "Shopping")
        case .vacation:
            return String(localized: "Vacation")
        case .anything:
            return String(localized: "Anything")
        }
    }

    var defaultTitle: String {
        switch self {
        case .shopping:
            return String(localized: "New Laptop")
        case .vacation:
            return String(localized: "Summer Vacation")
        case .anything:
            return String(localized: "My Savings Goal")
        }
    }
}
