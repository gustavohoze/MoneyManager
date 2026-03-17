import CoreData
import Foundation
import OSLog
import Combine

enum CloudKitUpgradeRequestOutcome {
    case alreadyUsingCloudKit
    case syncDisabled
    case noICloudAccount
    case queuedForNextLaunch

    var message: String {
        switch self {
        case .alreadyUsingCloudKit:
            return "CloudKit sync is already active."
        case .syncDisabled:
            return "CloudKit sync is disabled in app configuration."
        case .noICloudAccount:
            return "No iCloud account detected on this device."
        case .queuedForNextLaunch:
            return "CloudKit upgrade queued for next app launch."
        }
    }
}

@MainActor
final class PersistenceStoreManager: ObservableObject {
    private static let logger = Logger(subsystem: "shecraa.MoneyManager", category: "PersistenceStoreManager")

    @Published private(set) var controller: PersistenceController
    @Published private(set) var requiresAppRestartForCloudKitUpgrade = false

    init(controller: PersistenceController = .shared) {
        self.controller = controller
    }

    var viewContext: NSManagedObjectContext {
        controller.container.viewContext
    }

    func requestCloudKitUpgrade() -> CloudKitUpgradeRequestOutcome {
        guard CloudKitConstants.isSyncEnabledForCurrentRuntime else {
            return .syncDisabled
        }

        guard hasLikelyICloudAccount() else {
            return .noICloudAccount
        }

        guard controller.activeStoreMode != .cloudKitSQLite else {
            requiresAppRestartForCloudKitUpgrade = false
            return .alreadyUsingCloudKit
        }

        markUpgradeRequiresRestart()
        return .queuedForNextLaunch
    }

    private func markUpgradeRequiresRestart() {
        requiresAppRestartForCloudKitUpgrade = true
        #if DEBUG
        Self.logger.info("CloudKit upgrade deferred to next app launch to keep a single persistent stack instance in-process.")
        #endif
    }

    private func hasLikelyICloudAccount() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
}
