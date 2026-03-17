import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case appOpen = "app_open"
    case transactionCreated = "transaction_created"
    case transactionEdited = "transaction_edited"
    case transactionDeleted = "transaction_deleted"
    case categoryChanged = "category_changed"
    case accountCreated = "account_created"
    case merchantCorrected = "merchant_corrected"
}
