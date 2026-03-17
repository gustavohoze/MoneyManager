import SwiftUI

struct SettingsDataSyncPrivacyDetailPage: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.colorScheme) private var colorScheme
    let palette: FinanceTheme.Palette

    @State private var iCloudStatus = String(localized: "Not checked yet")
    @State private var isCheckingICloud = false
    @State private var actionFeedback = ""

    @AppStorage("settings.lockWithFaceID") private var lockWithFaceID = false
    @AppStorage("settings.hideBalances") private var hideBalances = false
    @AppStorage("settings.screenshotProtection") private var screenshotProtection = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // iCloud Sync section header
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "iCloud Sync"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Cloud Storage"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // iCloud status card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(palette.accent)
                            .frame(width: 32, height: 32)
                            .background(palette.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "iCloud Sync Status"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundStyle(palette.ink)
                            Text(iCloudStatus)
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }

                        Spacer()

                        if isCheckingICloud {
                            ProgressView()
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    Button {
                        Task {
                            await checkICloudAvailability()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(String(localized: "Check Availability"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(palette.accent)
                    }

                    Button {
                        actionFeedback = persistenceStoreManager.requestCloudKitUpgrade().message
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(String(localized: "Retry CloudKit Store"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(palette.accent)
                    }

                    if persistenceStoreManager.requiresAppRestartForCloudKitUpgrade {
                        Text(String(localized: "CloudKit upgrade will be applied on next app launch."))
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    if !actionFeedback.isEmpty {
                        Text(actionFeedback)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)

                Text(String(localized: "Active store mode: \(persistenceStoreManager.controller.activeStoreMode.rawValue)"))
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.vertical, 4)

                // Privacy section header
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Privacy & Security"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .textCase(.uppercase)
                    Text(String(localized: "Protect Your Data"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Face ID toggle
                SettingsSecurityCard(
                    icon: "faceid",
                    title: String(localized: "Lock with Face ID"),
                    description: String(localized: "Require Face ID to access the app"),
                    isEnabled: $lockWithFaceID,
                    palette: palette
                )

                // Hide balances toggle
                SettingsSecurityCard(
                    icon: "eye.slash.fill",
                    title: String(localized: "Hide Balances by Default"),
                    description: String(localized: "Tap to reveal payment method balances"),
                    isEnabled: $hideBalances,
                    palette: palette
                )

                // Screenshot protection toggle
                SettingsSecurityCard(
                    icon: "photo.on.rectangle.angled",
                    title: String(localized: "Screenshot Protection"),
                    description: String(localized: "Prevent screenshots in this app"),
                    isEnabled: $screenshotProtection,
                    palette: palette
                )

                // Info card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(palette.accent)
                        Text(String(localized: "Privacy settings help keep your financial data secure."))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
                .financeCard(palette: palette)
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Privacy & Security"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkICloudAvailability() async {
        isCheckingICloud = true
        defer { isCheckingICloud = false }
        let result = await ICloudAvailabilityService().checkAvailability()
        iCloudStatus = result.message
    }
}

struct SettingsSecurityCard: View {
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


