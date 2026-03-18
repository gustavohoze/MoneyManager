import SwiftUI

struct AddTransactionSaveButtonCard: View {
    var isSaving: Bool
    var isEnabled: Bool
    var titleKey: LocalizedStringKey = "Save Transaction"
    var palette: FinanceTheme.Palette
    var onSave: () -> Void

    var body: some View {
        Button {
            onSave()
        } label: {
            HStack {
                Image(systemName: isSaving ? "hourglass" : "checkmark.circle.fill")
                Text(titleKey)
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
        }
        .disabled(!isEnabled || isSaving)
        .padding(16)
        .background(isEnabled && !isSaving ? palette.accent : palette.secondaryInk)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
