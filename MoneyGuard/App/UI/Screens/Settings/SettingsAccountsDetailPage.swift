import SwiftUI

struct SettingsAccountsDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var isEditorPresented = false
    @State private var editorDraft = AccountEditorDraft.createDefault()
    @State private var paymentMethodPendingDeleteID: UUID?
    @AppStorage("settings.displayCurrencyCode") private var displayCurrencyCode: String = AppCurrency.currentCode

    private let paymentMethodTypeOptions = ["cash", "bank", "wallet", "credit"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add button card
                Button {
                    editorDraft = .createDefault()
                    editorDraft.currency = displayCurrencyCode
                    isEditorPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Add Payment Method"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.ink)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .financeCard(palette: palette)
                }

                // Payment methods list
                VStack(spacing: 12) {
                    if viewModel.paymentMethods.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(palette.accentSoft)
                            Text(String(localized: "No payment methods yet"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Add your first payment method to get started."))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .financeCard(palette: palette)
                    } else {
                        ForEach(viewModel.paymentMethods) { paymentMethod in
                            SettingsAccountCard(
                                paymentMethod: paymentMethod,
                                palette: palette,
                                onEdit: {
                                    editorDraft = AccountEditorDraft(
                                        paymentMethodID: paymentMethod.id,
                                        name: paymentMethod.name,
                                        type: paymentMethod.type,
                                        currency: displayCurrencyCode
                                    )
                                    isEditorPresented = true
                                },
                                onDelete: {
                                    paymentMethodPendingDeleteID = paymentMethod.id
                                }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Payment Methods"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditorPresented) {
            AccountEditorSheet(
                draft: $editorDraft,
                paymentMethodTypeOptions: paymentMethodTypeOptions,
                onCancel: {
                    isEditorPresented = false
                },
                onSave: {
                    viewModel.savePaymentMethod(
                        id: editorDraft.paymentMethodID,
                        name: editorDraft.name,
                        type: editorDraft.type,
                        currency: displayCurrencyCode
                    )
                    isEditorPresented = false
                }
            )
        }
        .confirmationDialog(
            String(localized: "Delete this payment method?"),
            isPresented: Binding(
                get: { paymentMethodPendingDeleteID != nil },
                set: { isPresented in
                    if !isPresented {
                        paymentMethodPendingDeleteID = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let paymentMethodID = paymentMethodPendingDeleteID {
                Button(String(localized: "Delete"), role: .destructive) {
                    viewModel.deletePaymentMethod(id: paymentMethodID)
                    paymentMethodPendingDeleteID = nil
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                paymentMethodPendingDeleteID = nil
            }
        }
    }
}

struct SettingsAccountCard: View {
    let paymentMethod: PaymentMethodListItem
    let palette: FinanceTheme.Palette
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon(for: paymentMethod.type))
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent)
                    .frame(width: 32, height: 32)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(paymentMethod.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text(paymentMethod.type.uppercased())
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            Text(paymentMethod.currency)
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
        }
        .financeCard(palette: palette)
    }

    private func icon(for type: String) -> String {
        switch type.lowercased() {
        case "credit": return "creditcard.fill"
        case "bank": return "building.2.fill"
        case "wallet": return "wallet.pass.fill"
        case "cash": return "banknote.fill"
        default: return "dollarsign.circle.fill"
        }
    }
}


