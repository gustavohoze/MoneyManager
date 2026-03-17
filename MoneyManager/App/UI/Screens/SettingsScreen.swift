import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @State private var actionFeedback = ""

    @ObservedObject var viewModel: SettingsViewModel

    @State private var isEditorPresented = false
    @State private var editorDraft = AccountEditorDraft.createDefault()
    @State private var accountPendingDeleteID: UUID?

    private let accountTypeOptions = ["cash", "bank", "wallet", "credit"]

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Accounts")) {
                    Button {
                        editorDraft = .createDefault()
                        isEditorPresented = true
                    } label: {
                        Label(String(localized: "Add PaymentMethod"), systemImage: "plus")
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))

                    if viewModel.accounts.isEmpty {
                        Text(String(localized: "No accounts yet"))
                            .foregroundStyle(palette.secondaryInk)
                    } else {
                        ForEach(viewModel.accounts) { account in
                            SettingsAccountRow(
                                account: account,
                                palette: palette,
                                onEdit: {
                                    editorDraft = AccountEditorDraft(
                                        paymentMethodID: account.id,
                                        name: account.name,
                                        type: account.type,
                                        currency: account.currency
                                    )
                                    isEditorPresented = true
                                },
                                onDelete: {
                                    accountPendingDeleteID = account.id
                                }
                            )
                        }
                    }
                }

                Section(String(localized: "Storage")) {
                    Text(
                        String(
                            format: String(localized: "Active store mode: %@"),
                            persistenceStoreManager.controller.activeStoreMode.rawValue
                        )
                    )
                }

                Section(String(localized: "Sync")) {
                    Button(String(localized: "Retry CloudKit Store")) {
                        actionFeedback = persistenceStoreManager.requestCloudKitUpgrade().message
                    }

                    if persistenceStoreManager.requiresAppRestartForCloudKitUpgrade {
                        Text(String(localized: "CloudKit upgrade will be applied on next app launch."))
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }

                    if !actionFeedback.isEmpty {
                        Text(actionFeedback)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }

                Section(String(localized: "Data Tools")) {
                    Button {
                        viewModel.createDummyTransactions()
                    } label: {
                        Label(String(localized: "Create Dummy Transactions"), systemImage: "plus.circle")
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))

                    Button(role: .destructive) {
                        viewModel.deleteDummyTransactions()
                    } label: {
                        Label(String(localized: "Delete Dummy Transactions"), systemImage: "trash")
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                }

                if let actionMessage = viewModel.actionMessage {
                    Section(String(localized: "Last Action")) {
                        Text(actionMessage)
                            .font(.footnote)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section(String(localized: "Error")) {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

#if DEBUG
                Section(String(localized: "Developer")) {
                    Toggle(String(localized: "Show Milestone 0 Examples"), isOn: $showMilestoneZeroExamples)
                }
#endif
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(FinanceTheme.pageBackground(for: colorScheme))
            .navigationTitle(String(localized: "Settings"))
            .onAppear {
                viewModel.loadAccounts()
            }
            .confirmationDialog(
                String(localized: "Delete this account?"),
                isPresented: Binding(
                    get: { accountPendingDeleteID != nil },
                    set: { isPresented in
                        if !isPresented {
                            accountPendingDeleteID = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                if let paymentMethodID = accountPendingDeleteID {
                    Button(String(localized: "Delete"), role: .destructive) {
                        viewModel.deletePaymentMethod(id: paymentMethodID)
                        accountPendingDeleteID = nil
                    }
                }

                Button(String(localized: "Cancel"), role: .cancel) {
                    accountPendingDeleteID = nil
                }
            }
            .sheet(isPresented: $isEditorPresented) {
                AccountEditorSheet(
                    draft: $editorDraft,
                    accountTypeOptions: accountTypeOptions,
                    onCancel: {
                        isEditorPresented = false
                    },
                    onSave: {
                        viewModel.saveAccount(
                            id: editorDraft.paymentMethodID,
                            name: editorDraft.name,
                            type: editorDraft.type,
                            currency: editorDraft.currency
                        )

                        isEditorPresented = false
                    }
                )
            }
        }
    }
}
