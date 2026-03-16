import CoreData
import Testing
@testable import MoneyManager

struct CoreDataModelTests {
    @Test("Test: Entity existence")
    func entityExistence_containsExpectedEntities() {
        // Objective: Verify Milestone 0 model defines exactly the required entities.
        // Given: A freshly generated managed object model.
        // When: Entity names are collected.
        // Then: Names exactly match Account, Transaction, Merchant, and Category.
        let model = CoreDataModelFactory.makeModel()
        let names = Set(model.entities.compactMap(\.name))

        #expect(names == ["Account", "Transaction", "Merchant", "Category"])
    }

    @Test("Test: Field validation - Account")
    func fieldValidation_account_matchesExpectedFields() {
        // Objective: Validate Account schema shape and attribute types.
        // Given: The Account entity from the generated model.
        // When: Attribute count and type metadata are inspected.
        // Then: Account has 5 expected fields with correct types.
        let model = CoreDataModelFactory.makeModel()
        let account = model.entitiesByName["Account"]

        #expect(account != nil)
        #expect(account?.attributesByName.count == 5)
        #expect(account?.attributesByName["id"]?.attributeType == .UUIDAttributeType)
        #expect(account?.attributesByName["name"]?.attributeType == .stringAttributeType)
        #expect(account?.attributesByName["type"]?.attributeType == .stringAttributeType)
        #expect(account?.attributesByName["currency"]?.attributeType == .stringAttributeType)
        #expect(account?.attributesByName["createdAt"]?.attributeType == .dateAttributeType)
    }

    @Test("Test: Field validation - Transaction")
    func fieldValidation_transaction_matchesExpectedFields() {
        // Objective: Validate Transaction schema key fields and types.
        // Given: The Transaction entity from the generated model.
        // When: Attribute count and selected attributes are verified.
        // Then: Transaction contains 11 attributes and expected types.
        let model = CoreDataModelFactory.makeModel()
        let transaction = model.entitiesByName["Transaction"]

        #expect(transaction != nil)
        #expect(transaction?.attributesByName.count == 11)
        #expect(transaction?.attributesByName["amount"]?.attributeType == .doubleAttributeType)
        #expect(transaction?.attributesByName["source"]?.attributeType == .stringAttributeType)
        #expect(transaction?.attributesByName["date"]?.attributeType == .dateAttributeType)
    }

    @Test("Test: Field validation - Merchant confidence")
    func fieldValidation_merchantConfidence_isDoubleType() {
        // Objective: Ensure merchant confidence is numeric and storable as Double.
        // Given: The Merchant entity from the generated model.
        // When: confidence attribute type is checked.
        // Then: confidence is a Double attribute.
        let model = CoreDataModelFactory.makeModel()
        let merchant = model.entitiesByName["Merchant"]

        #expect(merchant?.attributesByName["confidence"]?.attributeType == .doubleAttributeType)
    }
}
