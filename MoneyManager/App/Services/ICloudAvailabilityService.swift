import CloudKit
import Foundation

enum ICloudAvailabilityResult {
    case available
    case noAccount
    case restricted
    case temporarilyUnavailable
    case unknown

    var message: String {
        switch self {
        case .available:
            return String(localized: "iCloud is available. Sync can run across devices.")
        case .noAccount:
            return String(localized: "iCloud account is missing. Sign in to enable sync.")
        case .restricted:
            return String(localized: "iCloud is restricted on this device.")
        case .temporarilyUnavailable:
            return String(localized: "iCloud is temporarily unavailable. Try again later.")
        case .unknown:
            return String(localized: "Unable to determine iCloud status right now.")
        }
    }
}

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
