import SwiftUI

struct AddTransactionAmountSection: View {
    @Binding var amountText: String
    var focusedField: FocusState<AddTransactionFormField?>.Binding
    var onAmountTextChange: (String) -> Void

    var body: some View {
        Section {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Rp")
                    .font(.title2)

                TextField("0", text: $amountText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .tint(.primary)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .amount)
                    .onChange(of: amountText) { _, newValue in
                        onAmountTextChange(newValue)
                    }
            }
        } header: {
            Text("Amount")
        }
    }
}
