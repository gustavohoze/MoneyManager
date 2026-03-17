import SwiftUI

private enum ExpenseKeypadInputViewModel {
    static func appending(_ digit: String, to current: String) -> String {
        guard current.count < 15 else {
            return current
        }
        return current + digit
    }

    static func deletingLastCharacter(from current: String) -> String {
        guard !current.isEmpty else {
            return current
        }

        var updated = current
        updated.removeLast()
        return updated
    }
}

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
                    KeypadButton(label: "1") { amountText = ExpenseKeypadInputViewModel.appending("1", to: amountText) }
                    KeypadButton(label: "2") { amountText = ExpenseKeypadInputViewModel.appending("2", to: amountText) }
                    KeypadButton(label: "3") { amountText = ExpenseKeypadInputViewModel.appending("3", to: amountText) }
                }
                
                // Row 2: 4 5 6
                HStack(spacing: 8) {
                    KeypadButton(label: "4") { amountText = ExpenseKeypadInputViewModel.appending("4", to: amountText) }
                    KeypadButton(label: "5") { amountText = ExpenseKeypadInputViewModel.appending("5", to: amountText) }
                    KeypadButton(label: "6") { amountText = ExpenseKeypadInputViewModel.appending("6", to: amountText) }
                }
                
                // Row 3: 7 8 9
                HStack(spacing: 8) {
                    KeypadButton(label: "7") { amountText = ExpenseKeypadInputViewModel.appending("7", to: amountText) }
                    KeypadButton(label: "8") { amountText = ExpenseKeypadInputViewModel.appending("8", to: amountText) }
                    KeypadButton(label: "9") { amountText = ExpenseKeypadInputViewModel.appending("9", to: amountText) }
                }
                
                // Row 4: 00 0 ⌫
                HStack(spacing: 8) {
                    KeypadButton(label: "00") { amountText = ExpenseKeypadInputViewModel.appending("00", to: amountText) }
                    KeypadButton(label: "0") { amountText = ExpenseKeypadInputViewModel.appending("0", to: amountText) }
                    KeypadButton(label: "⌫") { amountText = ExpenseKeypadInputViewModel.deletingLastCharacter(from: amountText) }
                }
            }
        }
        .padding(.vertical, 4)
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
