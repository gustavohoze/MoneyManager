import CoreData
import Foundation
import Combine

@MainActor
final class MilestoneZeroExamplesViewModel: ObservableObject {

    @Published var persistenceOutput = String(localized: "Tap to inspect Core Data and CloudKit setup.")
    @Published var entityOutput = String(localized: "Tap to create sample Account, Transaction, Merchant, and Category records.")
    @Published var repositoryOutput = String(localized: "Tap to run repository fetch examples.")
    @Published var merchantResolverOutput = String(localized: "Tap to resolve a noisy merchant name.")
    @Published var analyticsOutput = String(localized: "Tap to fire example analytics events.")
    @Published var seedingOutput = String(localized: "Tap to seed the initial category set.")
    @Published var iCloudOutput = String(localized: "Tap to check iCloud availability.")
    @Published var exportOutput = String(localized: "Tap to generate CSV and JSON previews.")
    @Published var dataBrowserOutput = String(localized: "Tap refresh to inspect stored records.")

    @Published var csvPreview = ""
    @Published var jsonPreview = ""
    @Published var accountRows: [String] = []
    @Published var transactionRows: [String] = []
    @Published var merchantRows: [String] = []
    @Published var categoryRows: [String] = []
    @Published var customAccountName = "Cash"
    @Published var customAccountType = "cash"
    @Published var customAccountCurrency = "IDR"
    @Published var customTransactionAmount = "45000"
    @Published var customTransactionCurrency = "IDR"
    @Published var customTransactionMerchantRaw = "TRIJAYA PRATAMA TBK"
    @Published var customTransactionSource = "manual"
    @Published var customTransactionNote = "Coffee and groceries"
    @Published var customMerchantNormalizedName = ""
    @Published var customMerchantBrand = ""
    @Published var customMerchantCategory = "groceries"
    @Published var customMerchantConfidence = "0.92"
    @Published var customCategoryName = "Groceries"
    @Published var customCategoryIcon = "basket.fill"
    @Published var customCategoryType = "expense"

    let accountTypeOptions = ["cash", "bank", "wallet", "credit"]
    let transactionSourceOptions = ["manual", "voice", "bank_ocr", "receipt_ocr", "import"]
    let categoryTypeOptions = ["expense", "income"]

    private var configuredContextIdentifier: ObjectIdentifier?
    private var context: NSManagedObjectContext?

    private var accountRepository: AccountRepository?
    private var transactionRepository: TransactionRepository?
    private var merchantRepository: MerchantRepository?
    private var categoryRepository: CategoryRepository?

    private let merchantResolver: MerchantResolving
    private let analyticsService: AnalyticsTracking
    private let iCloudService: ICloudAvailabilityService
    private let exportService: ExportService

    init() {
        merchantResolver = MerchantResolver()
        analyticsService = InMemoryAnalyticsService()
        iCloudService = ICloudAvailabilityService()
        exportService = ExportService()
    }

    func configure(context: NSManagedObjectContext) {
        let newIdentifier = ObjectIdentifier(context)

        guard configuredContextIdentifier != newIdentifier else {
            return
        }

        configuredContextIdentifier = newIdentifier

        self.context = context

        accountRepository = CoreDataAccountRepository(context: context)
        transactionRepository = CoreDataTransactionRepository(context: context)
        merchantRepository = CoreDataMerchantRepository(context: context)
        categoryRepository = CoreDataCategoryRepository(context: context)
        refreshDataBrowser()
    }
    
    func showPersistenceExample() {
        let stores = context?.persistentStoreCoordinator?.persistentStores ?? []
        let storePaths = stores.compactMap { $0.url?.lastPathComponent }
        let cloudKitID = CloudKitConstants.containerIdentifier

        persistenceOutput = """
        Stores loaded: \(storePaths.count)
        Store files: \(storePaths.joined(separator: ", "))
        CloudKit container: \(cloudKitID)
        """
    }

    func runEntityExample() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            entityOutput = String(localized: "Repositories not configured.")
            return
        }
        
        do {
            let accountID = try accountRepository.ensureDefaultAccount()
            let transactionID = try transactionRepository.createExampleTransaction(accountID: accountID)
            let merchantID = try merchantRepository.upsertSampleMerchant(rawName: "TRIJAYA PRATAMA TBK")
            let insertedCategories = try categoryRepository.seedInitialCategories()

            entityOutput = """
            Account sample ID: \(accountID.uuidString)
            Transaction sample ID: \(transactionID.uuidString)
            Merchant sample ID: \(merchantID.uuidString)
            Categories inserted in this run: \(insertedCategories)
            """
            refreshDataBrowser()
        } catch {
            entityOutput = String(
                format: String(localized: "Entity example failed: %@"),
                error.localizedDescription
            )
        }
    }

    func createCustomRecords() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            entityOutput = String(localized: "Repositories not configured.")
            return
        }

        let trimmedAccountName = customAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrency = customAccountCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let trimmedMerchantRaw = customTransactionMerchantRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategoryName = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedAccountName.isEmpty else {
            entityOutput = String(localized: "Account name is required.")
            return
        }

        guard let amount = Double(customTransactionAmount), amount >= 0 else {
            entityOutput = String(localized: "Transaction amount must be a valid number.")
            return
        }

        guard !trimmedMerchantRaw.isEmpty else {
            entityOutput = String(localized: "Merchant raw name is required.")
            return
        }

        guard let confidence = Double(customMerchantConfidence), (0...1).contains(confidence) else {
            entityOutput = String(localized: "Merchant confidence must be between 0 and 1.")
            return
        }

        guard !trimmedCategoryName.isEmpty else {
            entityOutput = String(localized: "Category name is required.")
            return
        }

        do {
            let accountID = try accountRepository.upsertAccount(
                name: trimmedAccountName,
                type: customAccountType,
                currency: trimmedCurrency
            )

            let categoryID = try categoryRepository.upsertCategory(
                name: trimmedCategoryName,
                icon: customCategoryIcon,
                type: customCategoryType
            )

            let resolution = merchantResolver.resolve(rawMerchantName: trimmedMerchantRaw)
            let normalizedName = customMerchantNormalizedName.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalNormalizedName = normalizedName.isEmpty ? resolution.normalizedName : normalizedName
            let finalBrand = customMerchantBrand.trimmingCharacters(in: .whitespacesAndNewlines)

            let merchantID = try merchantRepository.upsertMerchant(
                rawName: trimmedMerchantRaw,
                normalizedName: finalNormalizedName,
                brand: finalBrand.isEmpty ? nil : finalBrand,
                category: customMerchantCategory,
                confidence: confidence
            )

            let transactionID = try transactionRepository.createTransaction(
                accountID: accountID,
                amount: amount,
                currency: trimmedCurrency,
                date: Date(),
                merchantRaw: trimmedMerchantRaw,
                merchantNormalized: finalNormalizedName,
                categoryID: categoryID,
                source: customTransactionSource,
                note: customTransactionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : customTransactionNote
            )

            entityOutput = """
            Custom account saved: \(trimmedAccountName)
            Custom category saved: \(trimmedCategoryName)
            Custom merchant saved: \(merchantID.uuidString)
            Custom transaction saved: \(transactionID.uuidString)
            """
            refreshDataBrowser()
        } catch {
            entityOutput = String(
                format: String(localized: "Custom save failed: %@"),
                error.localizedDescription
            )
        }
    }

    func runRepositoryExample() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            repositoryOutput = String(localized: "Repositories not configured.")
            return
        }
        do {
            let accounts = try accountRepository.fetchAccounts().count
            let transactions = try transactionRepository.fetchTransactions().count
            let merchants = try merchantRepository.fetchMerchants().count
            let categories = try categoryRepository.fetchCategories().count

            repositoryOutput = """
            Accounts fetched: \(accounts)
            Transactions fetched: \(transactions)
            Merchants fetched: \(merchants)
            Categories fetched: \(categories)
            """
        } catch {
            repositoryOutput = String(
                format: String(localized: "Repository example failed: %@"),
                error.localizedDescription
            )
        }
    }

    func runMerchantResolverExample() {
        let input = "TRIJAYA PRATAMA TBK"
        let result = merchantResolver.resolve(rawMerchantName: input)

        merchantResolverOutput = """
        Input: \(input)
        Normalized: \(result.normalizedName)
        Confidence: \(String(format: "%.2f", result.confidence))
        """
    }

    func runAnalyticsExample() {
        analyticsService.track(.appOpen)
        analyticsService.track(.transactionCreated)
        analyticsService.track(.categoryChanged)

        let names = analyticsService.allEvents().map(\.rawValue)
        analyticsOutput = "Tracked events: \(names.joined(separator: ", "))"
    }

    func runSeedingExample() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            seedingOutput = String(localized: "Repositories not configured.")
            return
        }
        do {
            let inserted = try categoryRepository.seedInitialCategories()
            let total = try categoryRepository.fetchCategories().count
            seedingOutput = "Seeded \(inserted) categories in this run. Total now: \(total)."
            refreshDataBrowser()
        } catch {
            seedingOutput = String(
                format: String(localized: "Seeding failed: %@"),
                error.localizedDescription
            )
        }
    }

    func runICloudAvailabilityExample() async {
        let result = await iCloudService.checkAvailability()
        iCloudOutput = result.message
    }

    func runExportExample() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            exportOutput = String(localized: "Repositories not configured.")
            return
        }
        do {
            let transactions = try transactionRepository.fetchTransactions()
            csvPreview = exportService.makeCSV(from: transactions)
            jsonPreview = exportService.makeJSON(from: transactions)
            exportOutput = "Export generated from \(transactions.count) transaction(s)."
        } catch {
            exportOutput = String(
                format: String(localized: "Export failed: %@"),
                error.localizedDescription
            )
            csvPreview = ""
            jsonPreview = ""
        }
    }

    func refreshDataBrowser() {
        guard
            let accountRepository,
            let transactionRepository,
            let merchantRepository,
            let categoryRepository
        else {
            dataBrowserOutput = String(localized: "Repositories not configured.")
            return
        }

        do {
            let accounts = try accountRepository.fetchAccounts()
            let transactions = try transactionRepository.fetchTransactions()
            let merchants = try merchantRepository.fetchMerchants()
            let categories = try categoryRepository.fetchCategories()

            accountRows = accounts.map { account in
                let name = (account.value(forKey: "name") as? String) ?? "-"
                let type = (account.value(forKey: "type") as? String) ?? "-"
                let currency = (account.value(forKey: "currency") as? String) ?? "-"
                return "\(name) | \(type) | \(currency)"
            }

            transactionRows = transactions.map { transaction in
                let merchant = (transaction.value(forKey: "merchantNormalized") as? String) ?? "-"
                let amount = (transaction.value(forKey: "amount") as? Double) ?? 0
                let source = (transaction.value(forKey: "source") as? String) ?? "-"
                return "\(merchant) | \(String(format: "%.0f", amount)) | \(source)"
            }

            merchantRows = merchants.map { merchant in
                let raw = (merchant.value(forKey: "rawName") as? String) ?? "-"
                let normalized = (merchant.value(forKey: "normalizedName") as? String) ?? "-"
                let confidence = (merchant.value(forKey: "confidence") as? Double) ?? 0
                return "\(raw) -> \(normalized) (\(String(format: "%.2f", confidence)))"
            }

            categoryRows = categories.map { category in
                let name = (category.value(forKey: "name") as? String) ?? "-"
                let type = (category.value(forKey: "type") as? String) ?? "-"
                return "\(name) | \(type)"
            }

            dataBrowserOutput = "Loaded: \(accounts.count) accounts, \(transactions.count) transactions, \(merchants.count) merchants, \(categories.count) categories."
        } catch {
            dataBrowserOutput = String(
                format: String(localized: "Data browser failed: %@"),
                error.localizedDescription
            )
            accountRows = []
            transactionRows = []
            merchantRows = []
            categoryRows = []
        }
    }
}
