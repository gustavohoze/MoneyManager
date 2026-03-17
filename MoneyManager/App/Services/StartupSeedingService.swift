import Foundation

struct StartupSeedingService {
    private let accountRepository: PaymentMethodRepository
    private let categoryRepository: CategoryRepository

    init(accountRepository: PaymentMethodRepository, categoryRepository: CategoryRepository) {
        self.accountRepository = accountRepository
        self.categoryRepository = categoryRepository
    }

    func seedMilestoneOneDefaults() throws {
        _ = try accountRepository.upsertPaymentMethod(name: "Cash", type: "cash", currency: "IDR")
        _ = try accountRepository.upsertPaymentMethod(name: "Bank", type: "bank", currency: "IDR")
        _ = try accountRepository.upsertPaymentMethod(name: "Credit Card", type: "credit", currency: "IDR")
        _ = try accountRepository.upsertPaymentMethod(name: "Wallet", type: "wallet", currency: "IDR")

        _ = try categoryRepository.seedInitialCategories()
        _ = try categoryRepository.upsertCategory(name: "Uncategorized", icon: "questionmark.circle", type: "expense")
    }
}
