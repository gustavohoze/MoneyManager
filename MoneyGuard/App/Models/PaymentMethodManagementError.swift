import Foundation

enum PaymentMethodManagementError: LocalizedError, Equatable {
    case paymentMethodInUse

    var errorDescription: String? {
        switch self {
        case .paymentMethodInUse:
            return "This payment method is used by transactions and cannot be deleted"
        }
    }
}
