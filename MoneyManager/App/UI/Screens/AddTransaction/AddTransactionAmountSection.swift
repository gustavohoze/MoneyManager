import SwiftUI

struct AddTransactionAmountSection: View {
    @Binding var amountText: String
    var focusedField: FocusState<AddTransactionFormField?>.Binding

    private static let displayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSize = 3
        f.groupingSeparator = ","
        f.maximumFractionDigits = 0
        return f
    }()

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
                        let digits = newValue.filter { $0.isNumber }
                        if let number = Double(digits), number > 0 {
                            let formatted = Self.displayFormatter.string(from: NSNumber(value: number)) ?? digits
                            if formatted != newValue {
                                amountText = formatted
                            }
                        } else if digits != newValue {
                            amountText = digits
                        }
                    }
            }
        } header: {
            Text("Amount")
        }
    }
}
