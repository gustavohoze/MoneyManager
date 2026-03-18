import SwiftUI

struct CategoryChipSelectorView: View {
    let categories: [TransactionFormCategoryOption]
    @Binding var selectedCategoryID: UUID?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Category"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(categories) { category in
                        CategoryChip(
                            label: category.name,
                            isSelected: selectedCategoryID == category.id,
                            action: { selectedCategoryID = category.id }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct CategoryChip: View {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected
                        ? palette.accent
                        : palette.cardBackground
                )
                .foregroundStyle(
                    isSelected
                        ? .white
                        : palette.secondaryInk
                )
                .cornerRadius(16)
        }
    }
}

struct AccountChipSelectorView: View {
    let accounts: [TransactionFormAccountOption]
    @Binding var selectedAccountID: UUID?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Payment Method"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.secondaryInk)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accounts) { account in
                        AccountChip(
                            label: account.name,
                            isSelected: selectedAccountID == account.id,
                            action: { selectedAccountID = account.id }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct AccountChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(.caption2, design: .rounded))
                
                Text(label)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? palette.accent.opacity(0.15)
                    : palette.cardBackground
            )
            .foregroundStyle(
                isSelected
                    ? palette.accent
                    : palette.secondaryInk
            )
            .cornerRadius(16)
        }
    }
}

#Preview {
    @Previewable @State var selectedCategory: UUID?
    @Previewable @State var selectedAccount: UUID?
    
    let categories = [
        TransactionFormCategoryOption(id: UUID(), name: "Food"),
        TransactionFormCategoryOption(id: UUID(), name: "Transport"),
        TransactionFormCategoryOption(id: UUID(), name: "Shopping"),
    ]
    
    let accounts = [
        TransactionFormAccountOption(id: UUID(), name: "Cash"),
        TransactionFormAccountOption(id: UUID(), name: "Bank"),
    ]
    
    return VStack(spacing: 16) {
        CategoryChipSelectorView(
            categories: categories,
            selectedCategoryID: $selectedCategory
        )
        
        AccountChipSelectorView(
            accounts: accounts,
            selectedAccountID: $selectedAccount
        )
        
        Spacer()
    }
    .padding()
}
