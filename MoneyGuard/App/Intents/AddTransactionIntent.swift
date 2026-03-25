import AppIntents
import CoreData
import Foundation

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Transaction"
    static var description = IntentDescription("Log a new financial transaction.")
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$merchant) in \(\.$category)")
    }

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Merchant")
    var merchant: String

    @Parameter(title: "Category")
    var category: CategoryAppEntity

    @Parameter(title: "Payment Method")
    var paymentMethod: PaymentMethodAppEntity?

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Note")
    var note: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let context = PersistenceController.shared.container.viewContext
        let transactionRepo = CoreDataTransactionRepository(context: context)
        let paymentRepo = CoreDataPaymentMethodRepository(context: context)
        let merchantResolver = MerchantResolver()
        let analytics = AnalyticsServiceFactory.makeDefault()
        
        let txDate = date ?? Date()
        
        // Resolve payment method or fallback to first available
        guard let resolvedPaymentMethodID = try await resolvePaymentMethodID(repo: paymentRepo) else {
            throw IntentError.message("No payment method available. Please add one in the app first.")
        }
        
        let resolvedCategoryID = resolveCategoryID()
        
        // Normalize Merchant
        let resolvedMerchant = merchantResolver.resolve(rawMerchantName: merchant)
        let normalizedMerchant = resolvedMerchant.normalizedName

        let formattedAmount = AppCurrency.formatted(amount)
        try await requestConfirmation(
            result: .result(
                dialog: IntentDialog("You're about to add \(formattedAmount) for \(merchant). Do you want to save it?")
            )
        )

        try transactionRepo.createTransaction(
            paymentMethodID: resolvedPaymentMethodID,
            amount: amount,
            currency: AppCurrency.currentCode,
            date: txDate,
            merchantRaw: merchant,
            merchantNormalized: normalizedMerchant,
            categoryID: resolvedCategoryID,
            source: "voice",
            note: note
        )

        // App Intents power both Siri voice logging and Shortcuts automation.
        analytics.track(.voiceLoggingUsed)
        analytics.track(.shortcutLoggingUsed)

        return .result(
            value: "Added \(formattedAmount) for \(merchant)",
            dialog: IntentDialog("Added \(formattedAmount) for \(merchant).")
        )
    }
    
    private func resolvePaymentMethodID(repo: PaymentMethodRepository) async throws -> UUID? {
        if let method = paymentMethod {
            return method.id
        }
        return try repo.fetchPaymentMethods().compactMap { $0.value(forKey: "id") as? UUID }.first
    }

    private func resolveCategoryID() -> UUID {
        return category.id
    }

    enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
        case message(String)

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .message(let text): return LocalizedStringResource(stringLiteral: text)
            }
        }
    }
}
