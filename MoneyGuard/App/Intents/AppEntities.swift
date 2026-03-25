import AppIntents
import CoreData
import Foundation

struct PaymentMethodAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Payment Method"
    static let defaultQuery = PaymentMethodAppEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct PaymentMethodAppEntityQuery: EntityQuery {
    func entities(for identifiers: [PaymentMethodAppEntity.ID]) async throws -> [PaymentMethodAppEntity] {
        let items = try await fetchAll()
        return items.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [PaymentMethodAppEntity] {
        try await fetchAll()
    }
    
    func defaultResult() async -> PaymentMethodAppEntity? {
        try? await fetchAll().first
    }

    private func fetchAll() async throws -> [PaymentMethodAppEntity] {
        let context = PersistenceController.shared.container.viewContext
        let repo = CoreDataPaymentMethodRepository(context: context)
        let methods = try repo.fetchPaymentMethods()
        return methods.compactMap { obj in
            guard let id = obj.value(forKey: "id") as? UUID,
                  let name = obj.value(forKey: "name") as? String else { return nil }
            return PaymentMethodAppEntity(id: id, name: name)
        }
    }
}

struct CategoryAppEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let defaultQuery = CategoryAppEntityQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CategoryAppEntityQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [CategoryAppEntity.ID]) async throws -> [CategoryAppEntity] {
        let items = try await fetchAll()
        return items.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        try await fetchAll()
    }
    
    func entities(matching string: String) async throws -> [CategoryAppEntity] {
        let items = try await fetchAll()
        return items.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    private func fetchAll() async throws -> [CategoryAppEntity] {
        let context = PersistenceController.shared.container.viewContext
        let repo = CoreDataCategoryRepository(context: context)
        let categories = try repo.fetchCategories()
        return categories.compactMap { obj in
            guard let id = obj.value(forKey: "id") as? UUID,
                  let name = obj.value(forKey: "name") as? String else { return nil }
            return CategoryAppEntity(id: id, name: name)
        }
    }
}
