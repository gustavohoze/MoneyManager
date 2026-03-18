import SwiftUI

struct AppToastState: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let isError: Bool
    let undoTitle: String?

    init(message: String, isError: Bool = false, undoTitle: String? = nil) {
        self.message = message
        self.isError = isError
        self.undoTitle = undoTitle
    }
}

struct AppToastView: View {
    let state: AppToastState
    let onUndo: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: state.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(state.isError ? Color.red : Color.green)

                if !state.message.isEmpty {
                    Text(state.message)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
            }

            if let onUndo {
                Button(action: onUndo) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                        Text(state.undoTitle ?? String(localized: "Undo"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}
