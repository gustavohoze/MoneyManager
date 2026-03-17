import SwiftUI

struct SettingsBudgetsDetailPage: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @AppStorage("settings.defaultMonthlyBudget") private var defaultMonthlyBudget: Double = 0
    @AppStorage("settings.budgetWarningThreshold") private var budgetWarningThreshold: Int = 75
    @AppStorage("settings.budgetCriticalThreshold") private var budgetCriticalThreshold: Int = 100

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Default budget card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Default Monthly Budget"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Your spending limit"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text(AppCurrency.formatted(defaultMonthlyBudget))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Stepper(
                        String(localized: "Adjust Monthly Budget"),
                        value: $defaultMonthlyBudget,
                        in: 0...500_000_000,
                        step: 100_000
                    )
                    .font(.system(.body, design: .rounded))
                }
                .financeCard(palette: palette)

                // Warning threshold card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Warning Level"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Alert when budget usage reaches \(budgetWarningThreshold)%"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text("\(budgetWarningThreshold)%")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.orange)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Stepper(
                        String(localized: "Adjust Warning Level"),
                        value: $budgetWarningThreshold,
                        in: 50...95,
                        step: 5
                    )
                    .font(.system(.body, design: .rounded))
                }
                .financeCard(palette: palette)

                // Critical threshold card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Critical Level"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(String(localized: "Alert when budget usage reaches \(budgetCriticalThreshold)%"))
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()
                        Text("\(budgetCriticalThreshold)%")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.red)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Stepper(
                        String(localized: "Adjust Critical Level"),
                        value: $budgetCriticalThreshold,
                        in: max(budgetWarningThreshold + 5, 80)...150,
                        step: 5
                    )
                    .font(.system(.body, design: .rounded))
                }
                .financeCard(palette: palette)

                // Category budgets info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "To set category-specific budgets, visit Transactions > Set Up Budget."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Budgets"))
        .navigationBarTitleDisplayMode(.inline)
    }
}


