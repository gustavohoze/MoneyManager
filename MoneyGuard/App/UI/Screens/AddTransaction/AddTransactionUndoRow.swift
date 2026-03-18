import SwiftUI

struct AddTransactionUndoRow: View {
    var message: String
    var canUndo: Bool
    var duplicateWarning: Bool
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline.weight(.medium))

                if canUndo {
                    Button("Undo", action: onUndo)
                        .font(.subheadline)
                }
            }

            Spacer()

            if duplicateWarning {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}
