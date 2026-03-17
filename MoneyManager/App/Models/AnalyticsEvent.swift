import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case appOpen = "app_open"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case transactionCreated = "transaction_created"
    case transactionEdited = "transaction_edited"
    case transactionDeleted = "transaction_deleted"
    case categoryChanged = "category_changed"
    case accountCreated = "account_created"
    case merchantCorrected = "merchant_corrected"
    case featureDashboardViewed = "feature_dashboard_viewed"
    case featureTransactionsViewed = "feature_transactions_viewed"
    case featureAddViewed = "feature_add_viewed"
    case featureSaveViewed = "feature_save_viewed"
    case featureSettingsViewed = "feature_settings_viewed"
}
