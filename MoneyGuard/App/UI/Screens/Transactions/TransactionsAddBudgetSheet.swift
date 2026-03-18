import SwiftUI

struct TransactionsAddBudgetSheet: View {
    let categories: [TransactionBudgetCategoryOption]
    let onSave: (_ category: String, _ amount: Double, _ isDefault: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategory: String = ""
    @State private var amountText: String = ""
    @State private var isDefaultBudget = false

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    private var canSave: Bool {
        !selectedCategory.isEmpty && (Double(amountText.filter { $0.isNumber }) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.icon).tag(category.name)
                            }
                        }
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Limit")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)

                        TextField("Amount", text: $amountText)
                            .keyboardType(.numberPad)
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use as default for all months", isOn: $isDefaultBudget)
                        Text(isDefaultBudget ? "This limit applies every month unless overridden." : "This limit applies only to the currently selected month.")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .financeCard(palette: palette)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let amount = Double(amountText.filter { $0.isNumber }) ?? 0
                        onSave(selectedCategory, amount, isDefaultBudget)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                if selectedCategory.isEmpty {
                    selectedCategory = categories.first?.name ?? ""
                }
            }
        }
    }
}
