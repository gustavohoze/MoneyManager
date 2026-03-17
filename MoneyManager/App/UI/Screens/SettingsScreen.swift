import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var path: [SettingsSection] = []

    @ObservedObject var viewModel: SettingsViewModel

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    enum SettingsSection: Hashable {
        case accountsAndIncome
        case budgets
        case categories
        case notifications
        case dataSyncPrivacy
        case advanced
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    // Top priority row: Payment Methods & Income
                    SettingsTileButton(
                        icon: "creditcard.fill",
                        label: String(localized: "Payment Methods & Income"),
                        description: "\(viewModel.paymentMethods.count) payment methods",
                        palette: palette
                    ) {
                        path.append(.accountsAndIncome)
                    }
                    .frame(maxWidth: .infinity)

                    // Second priority row: Budgets & Categories
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "chart.pie.fill",
                            label: String(localized: "Budgets"),
                            description: "Spending limits",
                            palette: palette
                        ) {
                            path.append(.budgets)
                        }

                        SettingsTileButton(
                            icon: "square.grid.2x2.fill",
                            label: String(localized: "Categories"),
                            description: "\(viewModel.categories.count) categories",
                            palette: palette
                        ) {
                            path.append(.categories)
                        }
                    }

                    // Third priority row: Notifications & Data/Sync/Privacy
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "bell.fill",
                            label: String(localized: "Notifications"),
                            description: "Alert settings",
                            palette: palette
                        ) {
                            path.append(.notifications)
                        }

                        SettingsTileButton(
                            icon: "lock.circle.fill",
                            label: String(localized: "Privacy"),
                            description: "Security & data",
                            palette: palette
                        ) {
                            path.append(.dataSyncPrivacy)
                        }
                    }

                    // Advanced row
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "wrench.adjustable.fill",
                            label: String(localized: "Advanced"),
                            description: "Debug & testing",
                            palette: palette
                        ) {
                            path.append(.advanced)
                        }

                        // Placeholder to keep 2-column layout
                        Color.clear
                            .frame(minHeight: 100)
                    }
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: SettingsSection.self) { section in
                switch section {
                case .accountsAndIncome:
                    SettingsAccountsAndIncomeDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                case .budgets:
                    SettingsBudgetsDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                case .categories:
                    SettingsCategoriesDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                case .notifications:
                    SettingsNotificationsDetailPage(palette: palette)
                case .dataSyncPrivacy:
                    SettingsDataSyncPrivacyDetailPage(palette: palette)
                case .advanced:
                    SettingsAdvancedDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                }
            }
            .onAppear {
                viewModel.loadSettingsData()
            }
        }
    }
}

// MARK: - Tile Button Component

struct SettingsTileButton: View {
    let icon: String
    let label: String
    let description: String
    let palette: FinanceTheme.Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(palette.accent)
                        .frame(width: 36, height: 36)
                        .background(palette.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.secondaryInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 100)
            .financeCard(palette: palette)
        }
    }
}
