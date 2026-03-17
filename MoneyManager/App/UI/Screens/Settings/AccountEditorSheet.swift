import SwiftUI

struct AccountEditorSheet: View {
    @Binding var draft: AccountEditorDraft

    let accountTypeOptions: [String]
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Name")) {
                    TextField(String(localized: "PaymentMethod Name"), text: $draft.name)
                }

                Section(String(localized: "Type")) {
                    Picker(String(localized: "PaymentMethod Type"), selection: $draft.type) {
                        ForEach(accountTypeOptions, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                }

                Section(String(localized: "Currency")) {
                    TextField(String(localized: "Currency"), text: $draft.currency)
                        .textInputAutocapitalization(.characters)
                }
            }
            .navigationTitle(draft.paymentMethodID == nil ? String(localized: "Add PaymentMethod") : String(localized: "Edit PaymentMethod"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel"), action: onCancel)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save"), action: onSave)
                }
            }
        }
    }
}
