import SwiftUI

struct SettingsAccountsAndIncomeDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var isEditorPresented = false
    @State private var editorDraft = AccountEditorDraft.createDefault()
    @State private var paymentMethodPendingDeleteID: UUID?

    @AppStorage("settings.salaryAmount") private var salaryAmount: Double = 0
    @AppStorage("settings.salaryFrequency") private var salaryFrequency: String = "Monthly"
    @AppStorage("settings.nextSalaryDate") private var nextSalaryDateTimestamp: Double = Date().timeIntervalSince1970
    @AppStorage("settings.displayCurrencyCode") private var displayCurrencyCode: String = AppCurrency.currentCode

    @State private var salaryAmountText: String = ""
    @State private var selectedDisplayCurrencyCode: String = AppCurrency.currentCode
    @State private var pendingDisplayCurrencyCode: String?
    @State private var isCurrencyWarningPresented = false
    @FocusState private var isSalaryAmountFocused: Bool

    private let paymentMethodTypeOptions = ["cash", "bank", "wallet", "credit"]
    private let salaryFrequencyOptions = ["Weekly", "Biweekly", "Monthly"]

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
                        ForEach(AppCurrency.commonCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .financeCard(palette: palette)

                Divider()
                    .padding(.vertical, 8)

                // INCOME SECTION
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Income"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Salary Configuration"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Salary amount card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Monthly Salary"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Your regular income"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(AppCurrency.formatted(salaryAmount))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    TextField(String(localized: "Enter amount"), text: $salaryAmountText)
                        .keyboardType(.numberPad)
                        .focused($isSalaryAmountFocused)
                        .font(.system(.body, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(palette.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(palette.cardBorder, lineWidth: 1)
                        )
                        .onChange(of: salaryAmountText) { newValue in
                            let digitsOnly = newValue.filter(\.isNumber)
                            if digitsOnly != newValue {
                                salaryAmountText = digitsOnly
                            }
                            salaryAmount = Double(digitsOnly) ?? 0
                        }
                }
                .financeCard(palette: palette)

                // Frequency card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Payment Frequency"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "How often you receive payment"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(salaryFrequency)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Picker(String(localized: "Frequency"), selection: $salaryFrequency) {
                        ForEach(salaryFrequencyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .financeCard(palette: palette)

                // Next payment date card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Next Payment Date"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Pick your upcoming salary payment date"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(nextSalaryDate, format: .dateTime.day().month().year())
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    DatePicker(
                        String(localized: "Next Payment Date"),
                        selection: nextSalaryDateBinding,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(FinanceTheme.pageBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(String(localized: "Payment Methods & Income"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) {
                    isSalaryAmountFocused = false
                }
            }
        }
        .onAppear {
            if salaryAmountText.isEmpty {
                salaryAmountText = salaryAmount > 0 ? String(Int(salaryAmount.rounded())) : ""
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

    private var nextSalaryDate: Date {
        Date(timeIntervalSince1970: nextSalaryDateTimestamp)
    }

    private var nextSalaryDateBinding: Binding<Date> {
        Binding(
            get: {
                let storedDate = nextSalaryDate
                return storedDate < Date() ? Date() : storedDate
            },
            set: { newValue in
                nextSalaryDateTimestamp = Calendar.current.startOfDay(for: newValue).timeIntervalSince1970
            }
        )
    }
}
