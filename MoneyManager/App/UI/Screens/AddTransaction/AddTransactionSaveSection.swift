import SwiftUI

struct AddTransactionSaveSection: View {
    var amountText: String
    var isSaving: Bool
    var onSave: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        Section {
            if let amount = Double(amountText.filter { $0.isNumber }), amount > 0 {
                Button(action: onSave) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Expense")
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
    }
}
