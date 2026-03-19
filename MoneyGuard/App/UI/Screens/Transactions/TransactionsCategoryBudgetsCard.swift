import SwiftUI

struct TransactionsCategoryBudgetsCard: View {
    let budgets: [TransactionCategoryBudgetPresentation]
    let canAddBudget: Bool
    let onAddBudget: () -> Void
    let onEditBudget: (TransactionCategoryBudgetPresentation) -> Void
    let onDeleteBudget: (TransactionCategoryBudgetPresentation) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category Budgets")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.ink)

                Spacer()

                Button("Add Budget", action: onAddBudget)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .buttonStyle(.plain)
                    .disabled(!canAddBudget)
            }

            if budgets.isEmpty {
                Text("No budgets yet. Add one to track spending limits per category.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
            } else {
                VStack(spacing: 10) {
                    ForEach(budgets) { budget in
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: budget.categoryIcon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(palette.ink)
                                    .frame(width: 24, height: 24)
                                    .background(palette.accentSoft.opacity(0.35))
                                    .clipShape(Circle())

                                Text(budget.category)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.ink)

                                if budget.isDefault {
                                    Text("Default")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(palette.secondaryInk)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .overlay(
                                            Capsule().stroke(palette.cardBorder, lineWidth: 1)
                                        )
                                }

                                Spacer()

                                Menu {
                                    Button("Edit") {
                                        onEditBudget(budget)
                                    }

                                    Button("Delete", role: .destructive) {
                                        onDeleteBudget(budget)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(palette.secondaryInk)
                                }
                                .buttonStyle(.plain)

                                Text("\(AppCurrency.formatted(max(budget.remainingValue, 0))) / \(budget.limitText)")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(palette.ink)
                            }

                            HStack {
                                Text("Spent: \(budget.spentText)")
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                                    .foregroundStyle(palette.secondaryInk)

                                Spacer()

                                Text(budget.isOverLimit ? "Missed" : "Achieved")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(budget.isOverLimit ? Color.red : Color.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background((budget.isOverLimit ? Color.red : Color.green).opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        if budget.id != budgets.last?.id {
                            Divider().overlay(palette.cardBorder)
                        }
                    }
                }
            }
        }
        .financeCard(palette: palette)
    }
}
