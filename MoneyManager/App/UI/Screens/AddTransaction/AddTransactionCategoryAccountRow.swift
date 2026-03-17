import SwiftUI

struct AddTransactionCategoryAccountRow: View {
    let categories: [TransactionFormCategoryOption]
    let accounts: [TransactionFormAccountOption]
    let selectedCategoryID: UUID?
    let selectedAccountID: UUID?
    let onSelectCategory: (UUID) -> Void
    let onSelectAccount: (UUID) -> Void

    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 0) {
                // Category picker
                Menu {
                    ForEach(categories) { cat in
                        Button { onSelectCategory(cat.id) } label: {
                            HStack {
                                Label(cat.name, systemImage: cat.icon)
                                if selectedCategoryID == cat.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    pickerLabel(
                        header: "Category",
                        icon: selectedCategory?.icon ?? "tag",
                        value: selectedCategoryName
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.vertical, 4)

                // Payment method picker
                Menu {
                    ForEach(accounts) { account in
                        Button { onSelectAccount(account.id) } label: {
                            HStack {
                                Label(account.name, systemImage: account.icon)
                                if selectedAccountID == account.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    pickerLabel(
                        header: "Payment Method",
                        icon: selectedAccount?.icon ?? "creditcard",
                        value: selectedAccountName
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func pickerLabel(header: String, icon: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(header)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }

    private var selectedCategory: TransactionFormCategoryOption? {
        categories.first { $0.id == selectedCategoryID }
    }

    private var selectedAccount: TransactionFormAccountOption? {
        accounts.first { $0.id == selectedAccountID }
    }

    private var selectedCategoryName: String {
        selectedCategory?.name ?? "Select"
    }

    private var selectedAccountName: String {
        selectedAccount?.name ?? "Select"
    }
}
