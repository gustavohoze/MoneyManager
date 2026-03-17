import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var path: [SettingsSection] = []

    @ObservedObject var viewModel: SettingsViewModel

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 16) {
                    // Top priority row: Payment Methods & Balance
                    SettingsTileButton(
                        icon: "creditcard.fill",
                        label: String(localized: "Payment Methods & Balance"),
                        description: viewModel.paymentMethodsDescription,
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
                            description: viewModel.categoriesDescription,
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

