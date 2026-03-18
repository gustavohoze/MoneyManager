import SwiftUI

struct UniversalToastState: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let isError: Bool
    let undoTitle: String?
    let icon: String?

    init(
        message: String,
        isError: Bool = false,
        undoTitle: String? = nil,
        icon: String? = nil
    ) {
        self.message = message
        self.isError = isError
        self.undoTitle = undoTitle
        self.icon = icon
    }
}

struct UniversalToastView: View {
    @Environment(\.colorScheme) private var colorScheme
    let state: UniversalToastState
    let palette: FinanceTheme.Palette
    let onUndo: (() -> Void)?
    let onClose: () -> Void

    private var iconName: String {
        if let icon = state.icon {
            return icon
        }
        return state.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
    }

    private var iconColor: Color {
        if state.isError {
            return Color(red: 0.95, green: 0.40, blue: 0.35)
        }
        return palette.accent
    }

    private var toastBackground: Color {
        colorScheme == .dark ? palette.cardBackground : palette.accentSoft
    }

    private var toastBorder: Color {
        colorScheme == .dark ? palette.cardBorder : palette.accent.opacity(0.25)
    }

    private var primaryText: Color {
        palette.ink
    }

    private var secondaryText: Color {
        palette.secondaryInk
    }

    private var undoBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.68)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)

                if !state.message.isEmpty {
                    Text(state.message)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(primaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(secondaryText)
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
                    .foregroundStyle(palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(undoBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(toastBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toastBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        VStack {
            UniversalToastView(
                state: UniversalToastState(
                    message: "Transaction saved successfully",
                    isError: false,
                    undoTitle: "Undo"
                ),
                palette: FinanceTheme.palette(for: .dark),
                onUndo: {},
                onClose: {}
            )
        }
        .padding(16)

        VStack {
            UniversalToastView(
                state: UniversalToastState(
                    message: "Failed to sync with iCloud",
                    isError: true
                ),
                palette: FinanceTheme.palette(for: .dark),
                onUndo: nil,
                onClose: {}
            )
        }
        .padding(16)

        VStack {
            UniversalToastView(
                state: UniversalToastState(
                    message: "Budget limit updated",
                    isError: false,
                    icon: "checkmark.circle.fill"
                ),
                palette: FinanceTheme.palette(for: .dark),
                onUndo: nil,
                onClose: {}
            )
        }
        .padding(16)
    }
    .background(FinanceTheme.pageBackground(for: .dark))
}
#endif
