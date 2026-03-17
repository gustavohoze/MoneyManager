import CoreData
import Foundation

enum CoreDataRepositoryError: LocalizedError {
    case missingEntity(String)
    case invalidValue(field: String, value: String)
    case missingReference(entity: String, id: UUID)

    var errorDescription: String? {
        switch self {
        case let .missingEntity(name):
            return "Missing Core Data entity: \(name)"
        case let .invalidValue(field, value):
            return "Invalid value for \(field): \(value)"
        case let .missingReference(entity, id):
            return "Missing reference \(entity) for id: \(id.uuidString)"
        }
    }
}

struct CoreDataPaymentMethodRepository: PaymentMethodRepository {
    private static let allowedTypes = Set(["cash", "bank", "wallet", "credit"])

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func ensureDefaultPaymentMethod() throws -> UUID {
        try upsertPaymentMethod(name: "Cash", type: "cash", currency: "IDR")
    }

    func upsertPaymentMethod(name: String, type: String, currency: String) throws -> UUID {
        let trimmedName = normalizedName(name)
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !trimmedName.isEmpty else {
            throw CoreDataRepositoryError.invalidValue(field: "account.name", value: name)
        }

        guard Self.allowedTypes.contains(normalizedType) else {
            throw CoreDataRepositoryError.invalidValue(field: "account.type", value: type)
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "PaymentMethod")
        request.predicate = NSPredicate(format: "name =[c] %@", trimmedName)
        request.fetchLimit = 1

        let account: NSManagedObject
        let id: UUID

        if let existing = try context.fetch(request).first,
           let existingID = existing.value(forKey: "id") as? UUID {
            account = existing
            id = existingID
        } else {
            account = NSManagedObject(entity: try entity(named: "PaymentMethod"), insertInto: context)
            id = UUID()
            account.setValue(id, forKey: "id")
            account.setValue(Date(), forKey: "createdAt")
        }

        account.setValue(trimmedName, forKey: "name")
        account.setValue(normalizedType, forKey: "type")
        account.setValue(normalizedCurrency, forKey: "currency")

        try context.save()
        return id
    }

    func fetchPaymentMethods() throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PaymentMethod")
        return try context.fetch(request)
    }

    func fetchPaymentMethod(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PaymentMethod")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let account = try context.fetch(request).first else {
            throw CoreDataRepositoryError.missingReference(entity: "PaymentMethod", id: id)
        }

        return account
    }

    func updatePaymentMethod(id: UUID, name: String, type: String, currency: String) throws {
        let trimmedName = normalizedName(name)
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !trimmedName.isEmpty else {
            throw CoreDataRepositoryError.invalidValue(field: "account.name", value: name)
        }

        guard Self.allowedTypes.contains(normalizedType) else {
            throw CoreDataRepositoryError.invalidValue(field: "account.type", value: type)
        }

        let duplicateNameRequest = NSFetchRequest<NSManagedObject>(entityName: "PaymentMethod")
        duplicateNameRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "name =[c] %@", trimmedName),
            NSPredicate(format: "id != %@", id as CVarArg)
        ])
        duplicateNameRequest.fetchLimit = 1

        if try !context.fetch(duplicateNameRequest).isEmpty {
            throw CoreDataRepositoryError.invalidValue(field: "account.name", value: name)
        }

        let account = try fetchPaymentMethod(id: id)
        account.setValue(trimmedName, forKey: "name")
        account.setValue(normalizedType, forKey: "type")
        account.setValue(normalizedCurrency, forKey: "currency")

        try context.save()
    }

    func deletePaymentMethod(id: UUID) throws {
        let account = try fetchPaymentMethod(id: id)
        context.delete(account)
        try context.save()
    }

    private func entity(named name: String) throws -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            throw CoreDataRepositoryError.missingEntity(name)
        }
        return entity
    }

    private func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

struct CoreDataTransactionRepository: TransactionRepository {
    private static let allowedSources = Set(["manual", "voice", "bank_ocr", "receipt_ocr", "import"])

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func createExampleTransaction(paymentMethodID: UUID) throws -> UUID {
        try createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 45000.0,
            currency: "IDR",
            date: Date(),
            merchantRaw: "TRIJAYA PRATAMA TBK",
            merchantNormalized: "Alfamart",
            categoryID: nil,
            source: "manual",
            note: "Example Milestone 0 transaction"
        )
    }

    func createTransaction(
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String,
        merchantNormalized: String?,
        categoryID: UUID?,
        source: String,
        note: String?
    ) throws -> UUID {
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard amount >= 0 else {
            throw CoreDataRepositoryError.invalidValue(field: "transaction.amount", value: "\(amount)")
        }

        guard Self.allowedSources.contains(normalizedSource) else {
            throw CoreDataRepositoryError.invalidValue(field: "transaction.source", value: source)
        }

        guard try entityExists(named: "PaymentMethod", id: paymentMethodID) else {
            throw CoreDataRepositoryError.missingReference(entity: "PaymentMethod", id: paymentMethodID)
        }

        if let categoryID,
           !(try entityExists(named: "Category", id: categoryID)) {
            throw CoreDataRepositoryError.missingReference(entity: "Category", id: categoryID)
        }

        let transaction = NSManagedObject(entity: try entity(named: "Transaction"), insertInto: context)
        let id = UUID()

        transaction.setValue(id, forKey: "id")
        transaction.setValue(paymentMethodID, forKey: "paymentMethodID")
        transaction.setValue(amount, forKey: "amount")
        transaction.setValue(normalizedCurrency, forKey: "currency")
        transaction.setValue(date, forKey: "date")
        transaction.setValue(merchantRaw, forKey: "merchantRaw")
        transaction.setValue(merchantNormalized, forKey: "merchantNormalized")
        transaction.setValue(categoryID, forKey: "categoryID")
        transaction.setValue(normalizedSource, forKey: "source")
        transaction.setValue(note, forKey: "note")
        transaction.setValue(Date(), forKey: "createdAt")

        try context.save()
        return id
    }

    func fetchTransactions() throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(request)
    }

    func fetchTransaction(id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let transaction = try context.fetch(request).first else {
            throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: id)
        }

        return transaction
    }

    func fetchTransactions(paymentMethodID: UUID) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "paymentMethodID == %@", paymentMethodID as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(request)
    }

    func fetchTransactions(from startDate: Date, to endDate: Date) throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(request)
    }

    func updateTransaction(
        id: UUID,
        paymentMethodID: UUID,
        amount: Double,
        currency: String,
        date: Date,
        merchantRaw: String,
        merchantNormalized: String?,
        categoryID: UUID?,
        note: String?
    ) throws {
        guard amount > 0 else {
            throw CoreDataRepositoryError.invalidValue(field: "transaction.amount", value: "\(amount)")
        }

        guard try entityExists(named: "PaymentMethod", id: paymentMethodID) else {
            throw CoreDataRepositoryError.missingReference(entity: "PaymentMethod", id: paymentMethodID)
        }

        if let categoryID,
           !(try entityExists(named: "Category", id: categoryID)) {
            throw CoreDataRepositoryError.missingReference(entity: "Category", id: categoryID)
        }

        let transaction = try fetchTransaction(id: id)
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        transaction.setValue(paymentMethodID, forKey: "paymentMethodID")
        transaction.setValue(amount, forKey: "amount")
        transaction.setValue(normalizedCurrency, forKey: "currency")
        transaction.setValue(date, forKey: "date")
        transaction.setValue(merchantRaw, forKey: "merchantRaw")
        transaction.setValue(merchantNormalized, forKey: "merchantNormalized")
        transaction.setValue(categoryID, forKey: "categoryID")
        transaction.setValue(note, forKey: "note")

        try context.save()
    }

    func deleteTransaction(id: UUID) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let transaction = try context.fetch(request).first else {
            throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: id)
        }

        context.delete(transaction)
        try context.save()
    }

    func detectDuplicate(
        paymentMethodID: UUID,
        amount: Double,
        date: Date,
        merchantNormalized: String?
    ) throws -> Bool {
        let calendar = Calendar(identifier: .iso8601)
        let dayStart = calendar.startOfDay(for: date)
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return false
        }

        var predicates: [NSPredicate] = [
            NSPredicate(format: "paymentMethodID == %@", paymentMethodID as CVarArg),
            NSPredicate(format: "amount == %f", amount),
            NSPredicate(format: "date >= %@ AND date < %@", dayStart as NSDate, nextDay as NSDate)
        ]

        if let merchantNormalized,
           !merchantNormalized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            predicates.append(NSPredicate(format: "merchantNormalized =[c] %@", merchantNormalized))
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1

        return try !context.fetch(request).isEmpty
    }

    func fetchDistinctMerchantRawNames(prefix: String, limit: Int) throws -> [String] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Transaction")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        if !prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.predicate = NSPredicate(format: "merchantRaw BEGINSWITH[cd] %@", prefix)
        } else {
            request.predicate = NSPredicate(format: "merchantRaw != nil AND merchantRaw != ''")
        }
        let transactions = try context.fetch(request)
        var seen = Set<String>()
        var results: [String] = []
        for tx in transactions {
            guard let name = tx.value(forKey: "merchantRaw") as? String else { continue }
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            if seen.insert(key).inserted {
                results.append(trimmed)
                if results.count >= limit { break }
            }
        }
        return results
    }

    private func entity(named name: String) throws -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            throw CoreDataRepositoryError.missingEntity(name)
        }
        return entity
    }

    private func entityExists(named entityName: String, id: UUID) throws -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try !context.fetch(request).isEmpty
    }
}

struct CoreDataMerchantRepository: MerchantRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func upsertSampleMerchant(rawName: String) throws -> UUID {
        try upsertMerchant(
            rawName: rawName,
            normalizedName: "Alfamart",
            brand: "Alfamart",
            category: "groceries",
            confidence: 0.92
        )
    }

    func upsertMerchant(
        rawName: String,
        normalizedName: String,
        brand: String?,
        category: String?,
        confidence: Double
    ) throws -> UUID {
        let normalizedRawName = normalizeText(rawName)
        let normalizedDisplayName = normalizeText(normalizedName)

        guard !normalizedRawName.isEmpty else {
            throw CoreDataRepositoryError.invalidValue(field: "merchant.rawName", value: rawName)
        }

        guard !normalizedDisplayName.isEmpty else {
            throw CoreDataRepositoryError.invalidValue(field: "merchant.normalizedName", value: normalizedName)
        }

        guard (0...1).contains(confidence) else {
            throw CoreDataRepositoryError.invalidValue(field: "merchant.confidence", value: "\(confidence)")
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Merchant")
        request.predicate = NSPredicate(format: "rawName =[c] %@", normalizedRawName)
        request.fetchLimit = 1

        let merchant: NSManagedObject
        let id: UUID

        if let existing = try context.fetch(request).first {
            merchant = existing
            id = (existing.value(forKey: "id") as? UUID) ?? UUID()
        } else {
            merchant = NSManagedObject(entity: try entity(named: "Merchant"), insertInto: context)
            id = UUID()
            merchant.setValue(id, forKey: "id")
            merchant.setValue(normalizedRawName, forKey: "rawName")
            merchant.setValue(Date(), forKey: "createdAt")
        }

        merchant.setValue(normalizedDisplayName, forKey: "normalizedName")
        merchant.setValue(brand, forKey: "brand")
        merchant.setValue(category, forKey: "category")
        merchant.setValue(confidence, forKey: "confidence")
        let usageCount = ((merchant.value(forKey: "usageCount") as? NSNumber)?.intValue) ?? 0
        merchant.setValue(usageCount + 1, forKey: "usageCount")
        merchant.setValue(Date(), forKey: "lastUsedDate")

        try context.save()
        return id
    }

    func fetchMerchants() throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Merchant")
        return try context.fetch(request)
    }

    private func entity(named name: String) throws -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            throw CoreDataRepositoryError.missingEntity(name)
        }
        return entity
    }

    private func normalizeText(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

struct CoreDataCategoryRepository: CategoryRepository {
    private static let allowedTypes = Set(["expense", "income"])

    private struct DefaultCategory {
        let name: String
        let icon: String
        let type: String
    }

    private let defaults: [DefaultCategory] = [
        .init(name: "Food", icon: "fork.knife", type: "expense"),
        .init(name: "Transport", icon: "car.fill", type: "expense"),
        .init(name: "Groceries", icon: "basket.fill", type: "expense"),
        .init(name: "Shopping", icon: "bag.fill", type: "expense"),
        .init(name: "Bills", icon: "doc.text.fill", type: "expense"),
        .init(name: "Entertainment", icon: "gamecontroller.fill", type: "expense"),
        .init(name: "Health", icon: "cross.case.fill", type: "expense"),
        .init(name: "Income", icon: "arrow.down.circle.fill", type: "income")
    ]

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func seedInitialCategories() throws -> Int {
        let existing = try fetchCategories()
        let existingNames = Set(existing.compactMap { $0.value(forKey: "name") as? String })

        var insertedCount = 0
        for category in defaults where !existingNames.contains(category.name) {
            _ = try upsertCategory(name: category.name, icon: category.icon, type: category.type)
            insertedCount += 1
        }

        return insertedCount
    }

    func upsertCategory(name: String, icon: String, type: String) throws -> UUID {
        let trimmedName = normalizedName(name)
        let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedName.isEmpty else {
            throw CoreDataRepositoryError.invalidValue(field: "category.name", value: name)
        }

        guard Self.allowedTypes.contains(normalizedType) else {
            throw CoreDataRepositoryError.invalidValue(field: "category.type", value: type)
        }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        request.predicate = NSPredicate(format: "name =[c] %@", trimmedName)
        request.fetchLimit = 1

        let categoryObject: NSManagedObject
        let id: UUID

        if let existing = try context.fetch(request).first,
           let existingID = existing.value(forKey: "id") as? UUID {
            categoryObject = existing
            id = existingID
        } else {
            categoryObject = NSManagedObject(entity: try entity(named: "Category"), insertInto: context)
            id = UUID()
            categoryObject.setValue(id, forKey: "id")
        }

        categoryObject.setValue(trimmedName, forKey: "name")
        categoryObject.setValue(icon, forKey: "icon")
        categoryObject.setValue(normalizedType, forKey: "type")

        try context.save()
        return id
    }

    func fetchCategories() throws -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request)
    }

    private func entity(named name: String) throws -> NSEntityDescription {
        guard let entity = NSEntityDescription.entity(forEntityName: name, in: context) else {
            throw CoreDataRepositoryError.missingEntity(name)
        }
        return entity
    }

    private func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
