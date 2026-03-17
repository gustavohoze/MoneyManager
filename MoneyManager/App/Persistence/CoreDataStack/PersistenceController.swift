import CoreData
import Foundation
import OSLog

final class PersistenceController {
    enum StoreMode: String {
        case cloudKitSQLite
        case localSQLite
        case inMemory
    }

    static let shared = PersistenceController()
    private static let logger = Logger(subsystem: "shecraa.MoneyManager", category: "Persistence")

    let container: NSPersistentCloudKitContainer
    let storeLoadErrorDescription: String?
    let isUsingFallbackStore: Bool
    let activeStoreMode: StoreMode
    static var initializationCount = 0

    init(inMemory: Bool = false) {
        // In-memory stores are used for tests/previews and must never register CloudKit schedulers.
        let canUseCloudKit = !inMemory && CloudKitConstants.isSyncEnabledForCurrentRuntime && Self.hasLikelyICloudAccount()

        Self.initializationCount += 1
        #if DEBUG
        Self.logger.debug("PersistenceController init count: \(Self.initializationCount, privacy: .public)")
        #endif
        let primaryAttempt = Self.makeContainer(
            inMemory: inMemory,
            enableCloudKit: canUseCloudKit,
            storeURL: nil
        )

        if primaryAttempt.errorDescription == nil {
            container = primaryAttempt.container
            storeLoadErrorDescription = nil
            isUsingFallbackStore = false
            if inMemory {
                activeStoreMode = .inMemory
            } else {
                activeStoreMode = canUseCloudKit ? .cloudKitSQLite : .localSQLite
            }
        } else {
            let sqliteFallbackAttempt = Self.makeContainer(
                inMemory: false,
                enableCloudKit: false,
                storeURL: Self.localFallbackStoreURL()
            )

            if sqliteFallbackAttempt.errorDescription == nil {
                container = sqliteFallbackAttempt.container
                storeLoadErrorDescription = primaryAttempt.errorDescription
                isUsingFallbackStore = true
                activeStoreMode = .localSQLite
                if let errorDescription = primaryAttempt.errorDescription {
                    #if DEBUG
                    Self.logger.error("Core Data primary CloudKit store failed, using local SQLite fallback: \(errorDescription, privacy: .public)")
                    #endif
                }
            } else {
                let memoryFallbackAttempt = Self.makeContainer(
                    inMemory: true,
                    enableCloudKit: false,
                    storeURL: URL(fileURLWithPath: "/dev/null")
                )
                container = memoryFallbackAttempt.container
                storeLoadErrorDescription = primaryAttempt.errorDescription ?? sqliteFallbackAttempt.errorDescription
                isUsingFallbackStore = true
                activeStoreMode = .inMemory
                if let errorDescription = storeLoadErrorDescription {
                    #if DEBUG
                    Self.logger.error("Core Data persistent stores failed, using in-memory fallback: \(errorDescription, privacy: .public)")
                    #endif
                }
            }
        }

        configureViewContext()
    }

    private static func makeContainer(
        inMemory: Bool,
        enableCloudKit: Bool,
        storeURL: URL?
    ) -> (container: NSPersistentCloudKitContainer, errorDescription: String?) {
        let model = CoreDataModelFactory.makeModel()
        let container = NSPersistentCloudKitContainer(name: "MoneyManager", managedObjectModel: model)

        guard let description = container.persistentStoreDescriptions.first else {
            return (container, "No persistent store description found")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if enableCloudKit {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: CloudKitConstants.containerIdentifier
            )
        } else {
            description.cloudKitContainerOptions = nil
        }

        if let storeURL {
            description.url = storeURL
        }

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        var errorDescription: String?
        let semaphore = DispatchSemaphore(value: 0)

        container.loadPersistentStores { _, error in
            if let error {
                errorDescription = Self.describe(error: error)
            }
            semaphore.signal()
        }

        semaphore.wait()
        return (container, errorDescription)
    }

    private static func localFallbackStoreURL() -> URL? {
        let fileManager = FileManager.default

        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directoryURL = baseURL.appendingPathComponent("MoneyManager", isDirectory: true)

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        return directoryURL.appendingPathComponent("MoneyManager.local.sqlite")
    }

    private static func hasLikelyICloudAccount() -> Bool {
        // Fast local check used at startup to avoid noisy CloudKit setup attempts.
        FileManager.default.ubiquityIdentityToken != nil
    }

    private static func describe(error: Error) -> String {
        let nsError = error as NSError
        var lines = [
            "\(nsError.domain) code \(nsError.code)",
            nsError.localizedDescription
        ]

        if let failureReason = nsError.localizedFailureReason {
            lines.append("Reason: \(failureReason)")
        }

        if let recoverySuggestion = nsError.localizedRecoverySuggestion {
            lines.append("Suggestion: \(recoverySuggestion)")
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            lines.append("Underlying: \(underlying.domain) code \(underlying.code) - \(underlying.localizedDescription)")
        }

        return lines.joined(separator: " | ")
    }

    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
