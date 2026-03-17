import SwiftUI

struct SettingsAccountsAndIncomeDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var isEditorPresented = false
    @State private var editorDraft = AccountEditorDraft.createDefault()
    @State private var paymentMethodPendingDeleteID: UUID?

    @AppStorage("settings.openingBalance") private var openingBalance: Double = 0
    @AppStorage("settings.displayCurrencyCode") private var displayCurrencyCode: String = AppCurrency.currentCode

    @State private var openingBalanceText: String = ""
    @State private var selectedDisplayCurrencyCode: String = AppCurrency.currentCode
    @State private var pendingDisplayCurrencyCode: String?
    @State private var isCurrencyWarningPresented = false
    @FocusState private var isOpeningBalanceFocused: Bool

    private let paymentMethodTypeOptions = ["cash", "bank", "wallet", "credit"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // PAYMENT METHODS SECTION
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Payment Methods"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Payment Methods"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
                    VStack(spacing: 12) {
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Display Currency"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Used for dashboard and budget amounts"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(selectedDisplayCurrencyCode)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Picker(String(localized: "Display Currency"), selection: $selectedDisplayCurrencyCode) {
                        ForEach(AppCurrency.allCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .financeCard(palette: palette)

                Divider()
                    .padding(.vertical, 8)

                // BALANCE SECTION
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Balance"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Opening Balance"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Opening balance card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Starting Balance"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Budget base before expenses"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(AppCurrency.formatted(openingBalance))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    TextField(String(localized: "Enter amount"), text: $openingBalanceText)
                        .keyboardType(.numberPad)
                        .focused($isOpeningBalanceFocused)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(palette.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(palette.cardBorder, lineWidth: 1)
                        )
                        .onChange(of: openingBalanceText) { newValue in
                            let digitsOnly = newValue.filter(\.isNumber)
                            if digitsOnly != newValue {
                                openingBalanceText = digitsOnly
                            }
                            openingBalance = Double(digitsOnly) ?? 0
                        }
                }
                .financeCard(palette: palette)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Use starting balance to track spending without depending on fixed income schedules."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(String(localized: "Payment Methods & Balance"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) {
                    isOpeningBalanceFocused = false
                }
            }
        }
        .onAppear {
            if openingBalanceText.isEmpty {
                openingBalanceText = openingBalance > 0 ? String(Int(openingBalance.rounded())) : ""
            }
            if let normalizedCurrency = AppCurrency.normalizedCode(displayCurrencyCode) {
                displayCurrencyCode = normalizedCurrency
                selectedDisplayCurrencyCode = normalizedCurrency
            } else {
                displayCurrencyCode = AppCurrency.currentCode
                selectedDisplayCurrencyCode = AppCurrency.currentCode
            }
        }
        .onChange(of: selectedDisplayCurrencyCode) { _, newValue in
            guard newValue != displayCurrencyCode else {
                return
            }
            pendingDisplayCurrencyCode = newValue
            selectedDisplayCurrencyCode = displayCurrencyCode
            isCurrencyWarningPresented = true
        }
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
            String(localized: "Change display currency?"),
            isPresented: $isCurrencyWarningPresented,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Change Currency"), role: .destructive) {
                guard let pendingDisplayCurrencyCode else {
                    return
                }
                displayCurrencyCode = pendingDisplayCurrencyCode
                selectedDisplayCurrencyCode = pendingDisplayCurrencyCode
                viewModel.syncPaymentMethodsCurrency(to: pendingDisplayCurrencyCode)
                self.pendingDisplayCurrencyCode = nil
            }

            Button(String(localized: "Cancel"), role: .cancel) {
                pendingDisplayCurrencyCode = nil
                selectedDisplayCurrencyCode = displayCurrencyCode
            }
        } message: {
            Text(String(localized: "Warning: Existing transaction amounts are not converted automatically. Numbers will stay the same and be shown with the new currency."))
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
