import SwiftUI

struct AddTransactionCategoryPickerCard: View {
    var selectedCategory: TransactionFormCategoryOption?
    let categories: [TransactionFormCategoryOption]
    let palette: FinanceTheme.Palette
    let onSelect: (UUID) -> Void
    var onCreateCategory: ((String) -> Void)? = nil

    @State private var showingCreateCategoryAlert = false
    @State private var newCategoryName = ""

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

                if onCreateCategory != nil {
                    Divider()

                    Button {
                        newCategoryName = ""
                        showingCreateCategoryAlert = true
                    } label: {
                        Label(String(localized: "Add Category"), systemImage: "plus")
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
        .alert(String(localized: "New Category"), isPresented: $showingCreateCategoryAlert) {
            TextField(String(localized: "Category name"), text: $newCategoryName)

            Button(String(localized: "Cancel"), role: .cancel) {
                newCategoryName = ""
            }

            Button(String(localized: "Add")) {
                onCreateCategory?(newCategoryName)
                newCategoryName = ""
            }
        } message: {
            Text(String(localized: "Create a custom category"))
        }
    }
}
