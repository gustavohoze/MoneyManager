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

    static func symbol(for code: String) -> String {
        let normalized = normalizedCode(code) ?? currentCode

        let preferredLocales = Locale.availableIdentifiers
            .map(Locale.init(identifier:))
            .filter { $0.currency?.identifier == normalized }

        for locale in preferredLocales {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            formatter.currencyCode = normalized

            if let symbol = formatter.currencySymbol,
               !symbol.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return symbol
            }
        }

        return normalized
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
