import SwiftUI

struct SettingsNotificationsDetailPage: View {
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @AppStorage("settings.notifyDailyWarning") private var notifyDailyWarning = true
    @AppStorage("settings.notifyBudgetExceeded") private var notifyBudgetExceeded = true
    @AppStorage("settings.notifyWeeklySummary") private var notifyWeeklySummary = true
    @AppStorage("settings.notifyUnusualSpending") private var notifyUnusualSpending = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Daily warning
                SettingsNotificationCard(
                    icon: "sunrise.fill",
                    title: String(localized: "Daily Spending Warning"),
                    description: String(localized: "Get reminded about your daily spending limits"),
                    isEnabled: $notifyDailyWarning,
                    palette: palette
                )

                // Budget exceeded
                SettingsNotificationCard(
                    icon: "exclamationmark.circle.fill",
                    title: String(localized: "Budget Exceeded"),
                    description: String(localized: "Alert when you exceed your category budgets"),
                    isEnabled: $notifyBudgetExceeded,
                    palette: palette
                )

                // Weekly summary
                SettingsNotificationCard(
                    icon: "calendar.circle.fill",
                    title: String(localized: "Weekly Summary"),
                    description: String(localized: "Receive a summary of your spending each week"),
                    isEnabled: $notifyWeeklySummary,
                    palette: palette
                )

                // Unusual spending
                SettingsNotificationCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: String(localized: "Unusual Spending Detected"),
                    description: String(localized: "Alert on unexpected spending patterns"),
                    isEnabled: $notifyUnusualSpending,
                    palette: palette
                )

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Enable system notifications in your device settings to receive these alerts."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Notifications"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsNotificationCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(palette.accent)
                    .frame(width: 32, height: 32)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
        }
        .padding(14)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}


