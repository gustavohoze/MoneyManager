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
