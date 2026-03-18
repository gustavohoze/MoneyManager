import SwiftUI
import UserNotifications

struct SettingsNotificationsDetailPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    let palette: FinanceTheme.Palette

    @AppStorage("settings.notifyDailyWarning") private var notifyDailyWarning = true
    @AppStorage("settings.notifyBudgetExceeded") private var notifyBudgetExceeded = true
    @AppStorage("settings.notifyWeeklySummary") private var notifyWeeklySummary = true
    @AppStorage("settings.notifyUnusualSpending") private var notifyUnusualSpending = true
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    private let notificationScheduler = LocalNotificationScheduler()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if notificationAuthorizationStatus != .authorized
                    && notificationAuthorizationStatus != .provisional
                    && notificationAuthorizationStatus != .ephemeral
                {
                    notificationPermissionCard
                }

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

                #if DEBUG
                debugTestSection
                #endif
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Notifications"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshNotificationAuthorizationStatus()
            await syncNotificationPreferences()
        }
        .onChange(of: notifyDailyWarning) { _, _ in
            Task { await syncNotificationPreferences() }
        }
        .onChange(of: notifyBudgetExceeded) { _, _ in
            Task { await syncNotificationPreferences() }
        }
        .onChange(of: notifyWeeklySummary) { _, _ in
            Task { await syncNotificationPreferences() }
        }
        .onChange(of: notifyUnusualSpending) { _, _ in
            Task { await syncNotificationPreferences() }
        }
    }

    private var notificationPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 30, height: 30)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(String(localized: "System Notifications Off"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)
            }

            Text(permissionCardDescription)
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)

            Button(permissionCardButtonTitle) {
                handleNotificationPermissionButtonTap()
            }
            .buttonStyle(.plain)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(palette.accent)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .financeCard(palette: palette)
    }

    private var permissionCardDescription: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return String(localized: "Enable notifications to receive reminders and weekly summaries.")
        case .denied:
            return String(localized: "Notifications are blocked for this app. Open iOS Settings to enable them.")
        default:
            return String(localized: "Enable notifications in iOS Settings to receive alerts.")
        }
    }

    private var permissionCardButtonTitle: String {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            return String(localized: "Enable Notifications")
        case .denied:
            return String(localized: "Open Settings")
        default:
            return String(localized: "Manage in Settings")
        }
    }

    private func handleNotificationPermissionButtonTap() {
        switch notificationAuthorizationStatus {
        case .notDetermined:
            Task {
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                await refreshNotificationAuthorizationStatus()
                await syncNotificationPreferences()
            }
        case .denied, .provisional, .ephemeral, .authorized:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        @unknown default:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        }
    }

    private func refreshNotificationAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationAuthorizationStatus = settings.authorizationStatus
        }
    }

    private func syncNotificationPreferences() async {
        await notificationScheduler.syncPreferences(
            dailyWarning: notifyDailyWarning,
            budgetExceeded: notifyBudgetExceeded,
            weeklySummary: notifyWeeklySummary,
            unusualSpending: notifyUnusualSpending
        )
        await refreshNotificationAuthorizationStatus()
    }

    #if DEBUG
    private var debugTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Debug Notification Tests"))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(palette.ink)

            Text(String(localized: "Schedules each notification type to fire in about 2 seconds."))
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)

            ForEach(LocalNotificationScheduler.DebugNotificationKind.allCases) { kind in
                Button {
                    Task {
                        await notificationScheduler.scheduleDebugNotification(kind: kind)
                        await refreshNotificationAuthorizationStatus()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text(debugButtonLabel(for: kind))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(palette.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .financeCard(palette: palette)
    }

    private func debugButtonLabel(for kind: LocalNotificationScheduler.DebugNotificationKind) -> String {
        switch kind {
        case .dailyWarning:
            return String(localized: "Test Daily Warning")
        case .budgetExceeded:
            return String(localized: "Test Budget Exceeded")
        case .weeklySummary:
            return String(localized: "Test Weekly Summary")
        case .unusualSpending:
            return String(localized: "Test Unusual Spending")
        }
    }
    #endif
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


