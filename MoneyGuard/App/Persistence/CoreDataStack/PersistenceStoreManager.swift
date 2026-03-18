import CoreData
import Foundation
import OSLog
import Combine

enum CloudKitUpgradeRequestOutcome {
    case alreadyUsingCloudKit
    case activatedInApp
    case syncDisabled
    case noICloudAccount
    case queuedForNextLaunch

    var message: String {
        switch self {
        case .alreadyUsingCloudKit:
            return "CloudKit sync is already active."
        case .activatedInApp:
            return "CloudKit sync was activated without restarting."
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

    init(controller: PersistenceController? = nil) {
        self.controller = controller ?? .shared
    }

    var viewContext: NSManagedObjectContext {
        controller.container.viewContext
    }

    func requestCloudKitUpgrade() -> CloudKitUpgradeRequestOutcome {
        guard CloudKitConstants.isSyncEnabledForCurrentRuntime else {
            return .syncDisabled
        }

        guard controller.activeStoreMode != .cloudKitSQLite else {
            requiresAppRestartForCloudKitUpgrade = false
            return .alreadyUsingCloudKit
        }

        if controller.container.viewContext.hasChanges {
            do {
                try controller.container.viewContext.save()
            } catch {
                #if DEBUG
                Self.logger.error("Failed to save pending changes before CloudKit upgrade attempt: \(error.localizedDescription, privacy: .public)")
                #endif
            }
        }

        let refreshedController = PersistenceController()
        if refreshedController.activeStoreMode == .cloudKitSQLite {
            controller = refreshedController
            requiresAppRestartForCloudKitUpgrade = false
            return .activatedInApp
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

}
