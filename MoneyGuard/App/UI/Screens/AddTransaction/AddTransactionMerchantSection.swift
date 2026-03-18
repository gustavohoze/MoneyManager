import SwiftUI

struct AddTransactionMerchantSection: View {
    @Binding var merchantText: String
    var suggestions: [MerchantSuggestion]
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    var onSelectSuggestion: (MerchantSuggestion) -> Void
    var onMerchantChange: (String) -> Void

    var body: some View {
        Section {
            MerchantAutocompleteView(
                merchantText: $merchantText,
                suggestions: suggestions,
                onSelectSuggestion: onSelectSuggestion
            )
            .onChange(of: merchantText) { _, newValue in
                onMerchantChange(newValue)
            }
            .focused(focusedField, equals: .merchant)
        } header: {
            Text("Merchant")
        }
    }
}
