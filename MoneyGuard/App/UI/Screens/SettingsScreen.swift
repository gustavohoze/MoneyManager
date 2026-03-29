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
                    // Top priority row: Payment Methods & Categories
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "creditcard.fill",
                            label: String(localized: "Payment Methods"),
                            description: viewModel.paymentMethodsDescription,
                            palette: palette
                        ) {
                            path.append(.accountsAndIncome)
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

                    // Second priority row: Achievements & Notifications
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "star.fill",
                            label: String(localized: "Achievements"),
                            description: "Earned badges",
                            palette: palette
                        ) {
                            path.append(.achievements)
                        }

                        SettingsTileButton(
                            icon: "bell.fill",
                            label: String(localized: "Notifications"),
                            description: "Alert settings",
                            palette: palette
                        ) {
                            path.append(.notifications)
                        }
                    }

                    // Third priority row: Privacy & Advanced
                    HStack(spacing: 12) {
                        SettingsTileButton(
                            icon: "lock.circle.fill",
                            label: String(localized: "Privacy"),
                            description: "Security & data",
                            palette: palette
                        ) {
                            path.append(.dataSyncPrivacy)
                        }
                    }

                    // ...existing code...
                }
                .padding(16)
            }
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if let toast = viewModel.toast {
                    UniversalToastView(
                        state: UniversalToastState(
                            message: toast.message,
                            isError: toast.isError,
                            undoTitle: toast.undoAction == nil ? nil : toast.undoTitle
                        ),
                        palette: palette,
                        onUndo: toast.undoAction == nil ? nil : {
                            viewModel.triggerToastUndo()
                        },
                        onClose: {
                            viewModel.dismissToast()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel.toast?.id)
            .task(id: viewModel.toast?.id) {
                guard viewModel.toast != nil else { return }
                try? await Task.sleep(for: .seconds(3.5))
                viewModel.dismissToast()
            }
            .navigationDestination(for: SettingsSection.self) { section in
                switch section {
                case .accountsAndIncome:
                    SettingsAccountsAndIncomeDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                case .categories:
                    SettingsCategoriesDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
                case .achievements:
                    SettingsAchievementsDetailPage(palette: palette)
                case .notifications:
                    SettingsNotificationsDetailPage(palette: palette)
                case .dataSyncPrivacy:
                    SettingsDataSyncPrivacyDetailPage(
                        viewModel: viewModel,
                        palette: palette
                    )
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

