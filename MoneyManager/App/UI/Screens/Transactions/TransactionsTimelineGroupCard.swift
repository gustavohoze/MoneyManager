import SwiftUI

struct TransactionsTimelineGroupCard: View {
    let groups: [TransactionTimeGroupPresentation]
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void
    var showsContainer: Bool = true

    @State private var collapsedGroups: Set<String> = []
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            let sections = Array(groups.enumerated())
            ForEach(sections, id: \.offset) { sectionIndex, group in
                let isCollapsed = collapsedGroups.contains(group.title)
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            if isCollapsed {
                                collapsedGroups.remove(group.title)
                            } else {
                                collapsedGroups.insert(group.title)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: sectionIcon(for: group))
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(sectionColor(for: group))

                            Text(group.title)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)

                            Spacer()

                            Text(group.totalSpentText)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.secondaryInk)

                            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.secondaryInk)
                                .padding(.leading, 4)
                        }
                    }
                    .buttonStyle(.plain)

                    if !isCollapsed {
                        let rows = Array(group.items.enumerated())
                        VStack(spacing: 0) {
                            ForEach(rows, id: \.offset) { rowIndex, item in
                                VStack(spacing: 0) {
                                    TransactionsTimelineRow(
                                        item: item,
                                        palette: palette,
                                        rowAccent: sectionColor(for: group),
                                        onEdit: { onEdit(item.id) },
                                        onDelete: { onDelete(item.id) }
                                    )

                                    if rowIndex < rows.count - 1 {
                                        Divider()
                                            .overlay(palette.accentSoft)
                                            .padding(.leading, 40)
                                    }
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }

                if sectionIndex < sections.count - 1 {
                    Divider()
                        .overlay(palette.cardBorder)
                }
            }
        }
        .modifier(ConditionalGroupCardModifier(enabled: showsContainer, palette: palette))
    }

    private func sectionColor(for group: TransactionTimeGroupPresentation) -> Color {
        switch group.title.lowercased() {
        case "morning":
            return .orange
        case "afternoon":
            return .teal
        case "evening":
            return .blue
        case "night":
            return .indigo
        default:
            return palette.accent
        }
    }

    private func sectionIcon(for group: TransactionTimeGroupPresentation) -> String {
        switch group.title.lowercased() {
        case "morning":
            return "sun.max.fill"
        case "afternoon":
            return "sun.haze.fill"
        case "evening", "night":
            return "moon.stars.fill"
        default:
            return "clock.fill"
        }
    }
}

private struct ConditionalGroupCardModifier: ViewModifier {
    let enabled: Bool
    let palette: FinanceTheme.Palette

    func body(content: Content) -> some View {
        if enabled {
            content.financeCard(palette: palette)
        } else {
            content
        }
    }
}

private struct TransactionsTimelineRow: View {
    let item: TransactionRowPresentation
    let palette: FinanceTheme.Palette
    let rowAccent: Color
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.categoryIcon)
                .foregroundStyle(rowAccent)
                .frame(width: 30, height: 30)
                .background(rowAccent.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(item.merchant)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Text(item.metaText)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(item.amountText)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.ink)

                Text(item.timeText)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button("Edit", action: onEdit)
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
