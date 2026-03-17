import Foundation

struct AccountEditorDraft {
    let paymentMethodID: UUID?
    var name: String
    var type: String
    var currency: String

    static func createDefault() -> AccountEditorDraft {
        AccountEditorDraft(paymentMethodID: nil, name: "", type: "cash", currency: "IDR")
    }
}
