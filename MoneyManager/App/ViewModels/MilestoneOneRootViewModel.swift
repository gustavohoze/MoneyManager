import Foundation
import CoreData
import Combine

@MainActor
final class MilestoneOneRootViewModel: ObservableObject {
    @Published private(set) var hasLoaded = false

    func markLoaded() {
        hasLoaded = true
    }

    func includesEntity(named entityName: String, in notification: Notification) -> Bool {
        let keys = [NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey]

        for key in keys {
            guard let objects = notification.userInfo?[key] as? Set<NSManagedObject> else {
                continue
            }

            if objects.contains(where: { $0.entity.name == entityName }) {
                return true
            }
        }

        return false
    }

    func shouldRefreshForCloudKitEvent(_ notification: Notification) -> Bool {
        guard
            let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event,
            event.endDate != nil
        else {
            return false
        }

        return event.type == .import || event.type == .export
    }
}
