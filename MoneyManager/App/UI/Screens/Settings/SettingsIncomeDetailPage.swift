import SwiftUI

struct SettingsIncomeDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @AppStorage("settings.salaryAmount") private var salaryAmount: Double = 0
    @AppStorage("settings.salaryFrequency") private var salaryFrequency: String = "Monthly"
    @AppStorage("settings.nextSalaryDate") private var nextSalaryDateTimestamp: Double = Date().timeIntervalSince1970

    @State private var salaryAmountText: String = ""
    @FocusState private var isSalaryAmountFocused: Bool

    private let salaryFrequencyOptions = ["Weekly", "Biweekly", "Monthly"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Your salary information helps calculate safe daily spending limits and financial forecasts."))
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
        .navigationTitle(String(localized: "Income"))
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


