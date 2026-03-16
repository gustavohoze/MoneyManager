import CloudKit
import CoreData
import Foundation
import OSLog
import Combine

@MainActor
final class PersistenceStoreManager: ObservableObject {
    private static let logger = Logger(subsystem: "shecraa.MoneyManager", category: "PersistenceStoreManager")

    @Published private(set) var controller: PersistenceController

    private var accountObserver: NSObjectProtocol?

    init(controller: PersistenceController = .shared) {
        self.controller = controller
        observeCloudKitAccountChanges()
    }

    deinit {
        if let accountObserver {
            NotificationCenter.default.removeObserver(accountObserver)
        }
    }

    var viewContext: NSManagedObjectContext {
        controller.container.viewContext
    }

    func refreshIfNeeded() {
        guard CloudKitConstants.isSyncEnabled else {
            return
        }

        guard hasLikelyICloudAccount() else {
            return
        }

        if controller.activeStoreMode != .cloudKitSQLite {
            reloadPreferredStore()
        }
    }

    func reloadPreferredStore() {
        let previousController = controller
        let updatedController = PersistenceController()

        if previousController.activeStoreMode == .localSQLite,
           updatedController.activeStoreMode == .cloudKitSQLite {
            migrateRecordsIfNeeded(from: previousController.container, to: updatedController.container)
        }

        controller = updatedController
    }

    private func migrateRecordsIfNeeded(
        from sourceContainer: NSPersistentCloudKitContainer,
        to destinationContainer: NSPersistentCloudKitContainer
    ) {
        let sourceContext = sourceContainer.newBackgroundContext()
        let destinationContext = destinationContainer.newBackgroundContext()

        let entityNames = ["Account", "Category", "Merchant", "Transaction"]

        destinationContext.performAndWait {
            sourceContext.performAndWait {
                for entityName in entityNames {
                    let request = NSFetchRequest<NSManagedObject>(entityName: entityName)

                    guard let sourceRecords = try? sourceContext.fetch(request) else {
                        continue
                    }

                    guard let destinationEntity = NSEntityDescription.entity(forEntityName: entityName, in: destinationContext),
                          destinationEntity.attributesByName["id"] != nil else {
                        continue
                    }

                    for sourceRecord in sourceRecords {
                        guard sourceRecord.entity.attributesByName["id"] != nil else {
                            continue
                        }

                        guard let id = sourceRecord.value(forKey: "id") as? UUID else {
                            continue
                        }

                        let existingRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
                        existingRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        existingRequest.fetchLimit = 1

                        let targetRecord: NSManagedObject
                        if let existing = try? destinationContext.fetch(existingRequest).first {
                            targetRecord = existing
                        } else {
                            targetRecord = NSManagedObject(entity: destinationEntity, insertInto: destinationContext)
                        }

                        for (key, _) in sourceRecord.entity.attributesByName {
                            targetRecord.setValue(sourceRecord.value(forKey: key), forKey: key)
                        }
                    }
                }

                if destinationContext.hasChanges {
                    do {
                        try destinationContext.save()
                        #if DEBUG
                        Self.logger.info("Migrated fallback local records into CloudKit-backed store.")
                        #endif
                    } catch {
                        #if DEBUG
                        Self.logger.error("Failed migrating fallback records: \(error.localizedDescription, privacy: .public)")
                        #endif
                    }
                }
            }
        }
    }

    private func observeCloudKitAccountChanges() {
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshIfNeeded()
            }
        }
    }

    private func hasLikelyICloudAccount() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
