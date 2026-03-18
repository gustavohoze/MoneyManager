import Foundation

enum MerchantSuggestionPresentationViewModel {
    static func relativeDateText(_ date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return String(localized: "Today")
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "Yesterday")
        }

        let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        return String(localized: "\(daysDiff)d ago")
    }
}
