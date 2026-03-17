import SwiftUI

struct AddTransactionCategoryPickerCard: View {
    var selectedCategory: TransactionFormCategoryOption?
    let categories: [TransactionFormCategoryOption]
    let palette: FinanceTheme.Palette
    let onSelect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: selectedCategory?.icon ?? "square.grid.2x2.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(palette.accent)

                Text(String(localized: "Category"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()
            }

            Menu {
                ForEach(categories, id: \.id) { category in
                    Button {
                        onSelect(category.id)
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                    }
                }
            } label: {
                HStack {
                    if let selected = selectedCategory {
                        Text(selected.name)
                            .foregroundStyle(palette.ink)
                            .lineLimit(1)
                    } else {
                        Text(String(localized: "Select"))
                            .foregroundStyle(palette.secondaryInk)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.secondaryInk)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}
