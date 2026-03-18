import SwiftUI

struct TransactionsFilterBar: View {
    let filters: [String]
    let selectedFilter: String
    let onSelectFilter: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    TransactionsFilterChip(
                        label: filter,
                        isSelected: filter == selectedFilter,
                        action: { onSelectFilter(filter) }
                    )
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct TransactionsFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? palette.accent : palette.cardBackground)
                .foregroundStyle(isSelected ? Color.white : palette.secondaryInk)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : palette.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
