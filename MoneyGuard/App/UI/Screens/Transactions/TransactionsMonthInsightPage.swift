import SwiftUI

struct TransactionsSetupBudgetPage: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @State private var isShowingBudgetSheet = false
    @State private var editingBudget: TransactionCategoryBudgetPresentation?
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                budgetOverviewCard

                TransactionsCategoryBudgetsCard(
                    budgets: viewModel.budgetSummary,
                    canAddBudget: !viewModel.budgetCategories.isEmpty,
                    onAddBudget: {
                        editingBudget = nil
                        isShowingBudgetSheet = true
                    },
                    onEditBudget: { budget in
                        editingBudget = budget
                        isShowingBudgetSheet = true
                    },
                    onDeleteBudget: { budget in
                        viewModel.deleteBudget(category: budget.category, isDefault: budget.isDefault)
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle("Set Up Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingBudgetSheet) {
            TransactionsAddBudgetSheet(
                categories: viewModel.budgetCategoryOptions,
                title: editingBudget == nil ? "Add Budget" : "Edit Budget",
                saveButtonTitle: editingBudget == nil ? "Save" : "Update",
                initialCategory: editingBudget?.category,
                initialAmount: editingBudget?.limitValue,
                initialIsDefault: editingBudget?.isDefault ?? false,
                allowsCategoryChange: editingBudget == nil,
                allowsScopeChange: editingBudget == nil,
                onSave: { category, amount, isDefault in
                    viewModel.saveBudget(category: category, amount: amount, isDefault: isDefault)
                }
            )
        }
    }

    private var budgetOverviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.presentation.monthSummary.monthTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white.opacity(0.92))

            Text("Budget Left")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.82))

            if viewModel.monthBudgetInsight.hasBudgets {
                Text("\(viewModel.monthBudgetInsight.budgetLeftText) / \(viewModel.monthBudgetInsight.totalBudgetText)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)

                Text(viewModel.monthBudgetInsight.achievedText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            } else {
                Text("No budget set yet")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}
