import SwiftUI

struct AddTransactionSaveSection: View {
    var isSaving: Bool
    var isEnabled: Bool
    var onSave: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        Section {
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
                .background(isEnabled ? palette.accent : palette.accent.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
}
