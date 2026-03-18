import CloudKit
import Foundation

struct ICloudAvailabilityService {
    func checkAvailability() async -> ICloudAvailabilityResult {
        do {
            let container = CKContainer(identifier: CloudKitConstants.containerIdentifier)
            let status = try await container.accountStatus()

            switch status {
            case .available:
                return .available
            case .noAccount:
                return .noAccount
            case .restricted:
                return .restricted
            case .temporarilyUnavailable:
                return .temporarilyUnavailable
            case .couldNotDetermine:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }
}
