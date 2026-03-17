import Foundation

enum AppCurrency {
    static let settingsKey = "settings.displayCurrencyCode"

    private static var fallbackCode: String {
        Locale.current.currency?.identifier ?? "IDR"
    }

    static var currentCode: String {
        guard let storedCode = UserDefaults.standard.string(forKey: settingsKey) else {
            return fallbackCode
        }

        return normalizedCode(storedCode) ?? fallbackCode
    }

    static var commonCodes: [String] {
        ["IDR", "USD", "EUR", "JPY", "GBP", "AUD", "SGD", "MYR"]
    }

    static var allCodes: [String] {
        Locale.commonISOCurrencyCodes.sorted()
    }

    static func formatted(_ value: Double) -> String {
        value.formatted(.currency(code: currentCode).precision(.fractionLength(0)))
    }

    static func normalizedCode(_ code: String) -> String? {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty else {
            return nil
        }

        if Locale.commonISOCurrencyCodes.contains(normalized) {
            return normalized
        }

        return nil
    }
}
