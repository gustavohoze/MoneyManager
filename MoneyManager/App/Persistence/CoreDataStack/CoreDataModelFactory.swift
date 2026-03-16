import CoreData

enum CoreDataModelFactory {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        model.entities = [
            makeAccountEntity(),
            makeTransactionEntity(),
            makeMerchantEntity(),
            makeCategoryEntity()
        ]
        return model
    }

    private static func makeAccountEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Account"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: UUID()),
            attribute(name: "name", type: .stringAttributeType, isOptional: false, defaultValue: ""),
            attribute(name: "type", type: .stringAttributeType, isOptional: false, defaultValue: "cash"),
            attribute(name: "currency", type: .stringAttributeType, isOptional: false, defaultValue: "IDR"),
            attribute(name: "createdAt", type: .dateAttributeType, isOptional: false, defaultValue: Date())
        ]
        return entity
    }

    private static func makeTransactionEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Transaction"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: UUID()),
            attribute(name: "accountID", type: .UUIDAttributeType, isOptional: false, defaultValue: UUID()),
            attribute(name: "amount", type: .doubleAttributeType, isOptional: false, defaultValue: 0.0),
            attribute(name: "currency", type: .stringAttributeType, isOptional: false, defaultValue: "IDR"),
            attribute(name: "date", type: .dateAttributeType, isOptional: false, defaultValue: Date()),
            attribute(name: "merchantRaw", type: .stringAttributeType, isOptional: true),
            attribute(name: "merchantNormalized", type: .stringAttributeType, isOptional: true),
            attribute(name: "categoryID", type: .UUIDAttributeType, isOptional: true),
            attribute(name: "source", type: .stringAttributeType, isOptional: false, defaultValue: "manual"),
            attribute(name: "note", type: .stringAttributeType, isOptional: true),
            attribute(name: "createdAt", type: .dateAttributeType, isOptional: false, defaultValue: Date())
        ]
        return entity
    }

    private static func makeMerchantEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Merchant"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: UUID()),
            attribute(name: "rawName", type: .stringAttributeType, isOptional: false, defaultValue: ""),
            attribute(name: "normalizedName", type: .stringAttributeType, isOptional: false, defaultValue: ""),
            attribute(name: "brand", type: .stringAttributeType, isOptional: true),
            attribute(name: "category", type: .stringAttributeType, isOptional: true),
            attribute(name: "confidence", type: .doubleAttributeType, isOptional: false, defaultValue: 0.0),
            attribute(name: "createdAt", type: .dateAttributeType, isOptional: false, defaultValue: Date())
        ]
        return entity
    }

    private static func makeCategoryEntity() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Category"
        entity.managedObjectClassName = "NSManagedObject"
        entity.properties = [
            attribute(name: "id", type: .UUIDAttributeType, isOptional: false, defaultValue: UUID()),
            attribute(name: "name", type: .stringAttributeType, isOptional: false, defaultValue: ""),
            attribute(name: "icon", type: .stringAttributeType, isOptional: false, defaultValue: "questionmark.circle"),
            attribute(name: "type", type: .stringAttributeType, isOptional: false, defaultValue: "expense")
        ]
        return entity
    }

    private static func attribute(
        name: String,
        type: NSAttributeType,
        isOptional: Bool,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        attribute.defaultValue = defaultValue
        return attribute
    }
}
