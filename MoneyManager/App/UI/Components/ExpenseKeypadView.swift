import SwiftUI

struct ExpenseKeypadView: View {
    @Binding var amountText: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Keypad Grid (3 columns)
            VStack(spacing: 8) {
                // Row 1: 1 2 3
                HStack(spacing: 8) {
                    KeypadButton(label: "1") { appendDigit("1") }
                    KeypadButton(label: "2") { appendDigit("2") }
                    KeypadButton(label: "3") { appendDigit("3") }
                }
                
                // Row 2: 4 5 6
                HStack(spacing: 8) {
                    KeypadButton(label: "4") { appendDigit("4") }
                    KeypadButton(label: "5") { appendDigit("5") }
                    KeypadButton(label: "6") { appendDigit("6") }
                }
                
                // Row 3: 7 8 9
                HStack(spacing: 8) {
                    KeypadButton(label: "7") { appendDigit("7") }
                    KeypadButton(label: "8") { appendDigit("8") }
                    KeypadButton(label: "9") { appendDigit("9") }
                }
                
                // Row 4: 00 0 ⌫
                HStack(spacing: 8) {
                    KeypadButton(label: "00") { appendDigit("00") }
                    KeypadButton(label: "0") { appendDigit("0") }
                    KeypadButton(label: "⌫") { deleteLastCharacter() }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func appendDigit(_ digit: String) {
        // Limit to reasonable amount (max 15 digits before decimal)
        if amountText.count < 15 {
            amountText.append(digit)
        }
    }
    
    private func deleteLastCharacter() {
        if !amountText.isEmpty {
            amountText.removeLast()
        }
    }
}

struct KeypadButton: View {
    let label: String
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(palette.cardBackground)
                .cornerRadius(12)
        }
    }
}

#Preview {
    @State var amount = ""
    return ExpenseKeypadView(amountText: $amount)
        .padding()
}
