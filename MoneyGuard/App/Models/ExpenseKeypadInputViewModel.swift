import Foundation

enum ExpenseKeypadInputViewModel {
    static func appending(_ digit: String, to current: String) -> String {
        guard current.count < 15 else {
            return current
        }
        return current + digit
    }

    static func deletingLastCharacter(from current: String) -> String {
        guard !current.isEmpty else {
            return current
        }

        var updated = current
        updated.removeLast()
        return updated
    }
}
