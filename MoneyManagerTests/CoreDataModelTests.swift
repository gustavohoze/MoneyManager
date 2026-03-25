import CoreData
import Testing
@testable import Money_Guard

struct CoreDataModelTests {
    @Test("Test: Entity existence")
    func entityExistence_containsExpectedEntities() {
        // Objective: Verify the model defines exactly the required entities.
        // Given: A freshly generated managed object model.
        // When: Entity names are collected.
        // Then: Names exactly match Account, Transaction, Merchant, Category, and SavingPlan.
        let model = CoreDataModelFactory.makeModel()
        let names = Set(model.entities.compactMap(\.name))

        #expect(names == ["Account", "Transaction", "Merchant", "Category", "SavingPlan"])
    }

    @Test("Test: Field validation - PaymentMethod")
    func fieldValidation_account_matchesExpectedFields() {
        // Objective: Validate PaymentMethod schema shape and attribute types.
        // Given: The Account entity used by the PaymentMethod domain.
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
        #expect(merchant?.attributesByName["usageCount"]?.attributeType == .integer64AttributeType)
        #expect(merchant?.attributesByName["lastUsedDate"]?.attributeType == .dateAttributeType)
    }

    @Test("Test: Field validation - SavingPlan")
    func fieldValidation_savingPlan_matchesExpectedFields() {
        // Objective: Validate SavingPlan schema key fields and types.
        // Given: The SavingPlan entity from the generated model.
        // When: Attribute count and selected attributes are verified.
        // Then: SavingPlan contains 8 attributes and expected types.
        let model = CoreDataModelFactory.makeModel()
        let savingPlan = model.entitiesByName["SavingPlan"]

        #expect(savingPlan != nil)
        #expect(savingPlan?.attributesByName.count == 8)
        #expect(savingPlan?.attributesByName["goalType"]?.attributeType == .stringAttributeType)
        #expect(savingPlan?.attributesByName["goalTitle"]?.attributeType == .stringAttributeType)
        #expect(savingPlan?.attributesByName["targetAmount"]?.attributeType == .doubleAttributeType)
        #expect(savingPlan?.attributesByName["currentSavings"]?.attributeType == .doubleAttributeType)
        #expect(savingPlan?.attributesByName["timeframeMonths"]?.attributeType == .integer64AttributeType)
        #expect(savingPlan?.attributesByName["plannedMonthlyDeposit"]?.attributeType == .doubleAttributeType)
        #expect(savingPlan?.attributesByName["updatedAt"]?.attributeType == .dateAttributeType)
    }
}
