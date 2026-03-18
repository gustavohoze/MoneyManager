import SwiftUI

struct SettingsToastView: View {
    let state: SettingsToastState
    let onUndo: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: state.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(state.isError ? Color.red : Color.green)

            Text(state.message)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if state.undoAction != nil {
                Button(state.undoTitle ?? String(localized: "Undo")) {
                    onUndo()
                }
                .buttonStyle(.plain)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.20), in: Capsule())
            }

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
    }
}
