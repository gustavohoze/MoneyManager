import SwiftUI

struct TransactionEditSheetView: View {
    let state: TransactionEditState
    let onCancel: () -> Void
    let onSave: (TransactionEditDraft) -> Void
    let onDelete: () -> Void

    @StateObject private var viewModel = TransactionEditSheetViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Amount"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        TextField(String(localized: "Amount"), text: $viewModel.editAmountText)
                            .keyboardType(.decimalPad)
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Merchant"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        TextField(String(localized: "Merchant"), text: $viewModel.editMerchantRaw)
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Category"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        Picker(String(localized: "Category"), selection: $viewModel.editSelectedCategoryID) {
                            ForEach(state.options.categories) { option in
                                Text(option.name).tag(Optional(option.id))
                            }
                        }
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Payment Method"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        Picker(String(localized: "Payment Method"), selection: $viewModel.editSelectedAccountID) {
                            ForEach(state.options.accounts) { option in
                                Text(option.name).tag(Optional(option.id))
                            }
                        }
                    }
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Date"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        DatePicker(String(localized: "Transaction Date"), selection: $viewModel.editDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .financeCard(palette: palette)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "Note"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.secondaryInk)
                        TextField(String(localized: "Optional Note"), text: $viewModel.editNote)
                    }
                    .financeCard(palette: palette)

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Transaction")
                            Spacer()
                        }
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle(String(localized: "Edit Transaction"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Save")) {
                        guard let updatedDraft = viewModel.makeDraft(from: state) else {
                            return
                        }
                        onSave(updatedDraft)
                    }
                    .disabled(!viewModel.canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "Done")) {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .onAppear {
                viewModel.load(from: state)
            }
        }
    }
}
