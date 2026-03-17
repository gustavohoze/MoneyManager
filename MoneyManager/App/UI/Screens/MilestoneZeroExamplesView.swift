import SwiftUI
import CoreData

struct MilestoneZeroExamplesView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @StateObject private var viewModel = MilestoneZeroExamplesViewModel()
    @State private var lastActionMessage = ""

    var body: some View {
        List {
#if DEBUG
            Section(String(localized: "Developer")) {
                Button(String(localized: "Back to Milestone 1")) {
                    showMilestoneZeroExamples = false
                    lastActionMessage = String(localized: "Returned to Milestone 1 app shell.")
                }
            }
#endif

            Section(String(localized: "Store Status")) {
                Text(
                    String(
                        format: String(localized: "Active store mode: %@"),
                        persistenceStoreManager.controller.activeStoreMode.rawValue
                    )
                )
                    .font(.footnote)

                if let error = persistenceStoreManager.controller.storeLoadErrorDescription,
                   !error.isEmpty {
                    Text(
                        String(
                            format: String(localized: "Last store error: %@"),
                            error
                        )
                    )
                        .font(.footnote)
                        .textSelection(.enabled)
                }

                Button(String(localized: "Retry CloudKit Store")) {
                    lastActionMessage = persistenceStoreManager.requestCloudKitUpgrade().message
                }
            }

            if !lastActionMessage.isEmpty {
                Section(String(localized: "Last Action")) {
                    Text(lastActionMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(String(localized: "0.1 Project Structure")) {
                Text(String(localized: "UI / ViewModels / Persistence / Repositories / Services / Extensions"))
                    .font(.subheadline)
            }

            Section(String(localized: "0.2 Persistence Architecture")) {
                Button(String(localized: "Show Persistence Example")) {
                    viewModel.showPersistenceExample()
                    lastActionMessage = String(localized: "Loaded persistence details.")
                }
                Text(viewModel.persistenceOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.3 Core Data Entities")) {
                Button(String(localized: "Create Entity Examples")) {
                    viewModel.runEntityExample()
                    lastActionMessage = String(localized: "Created sample entity records.")
                }
                Text(viewModel.entityOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "Custom Data Entry")) {
                TextField(String(localized: "PaymentMethod Name"), text: $viewModel.customAccountName)

                Picker(String(localized: "PaymentMethod Type"), selection: $viewModel.customAccountType) {
                    ForEach(viewModel.accountTypeOptions, id: \.self) { option in
                        Text(option)
                    }
                }

                TextField(String(localized: "PaymentMethod Currency"), text: $viewModel.customAccountCurrency)

                TextField(String(localized: "Transaction Amount"), text: $viewModel.customTransactionAmount)
                    .keyboardType(.decimalPad)
                TextField(String(localized: "Transaction Currency"), text: $viewModel.customTransactionCurrency)
                TextField(String(localized: "Merchant Raw Name"), text: $viewModel.customTransactionMerchantRaw)

                Picker(String(localized: "Transaction Source"), selection: $viewModel.customTransactionSource) {
                    ForEach(viewModel.transactionSourceOptions, id: \.self) { option in
                        Text(option)
                    }
                }

                TextField(String(localized: "Transaction Note"), text: $viewModel.customTransactionNote)

                TextField(String(localized: "Merchant Normalized Name"), text: $viewModel.customMerchantNormalizedName)
                TextField(String(localized: "Merchant Brand"), text: $viewModel.customMerchantBrand)
                TextField(String(localized: "Merchant Category"), text: $viewModel.customMerchantCategory)
                TextField(String(localized: "Merchant Confidence"), text: $viewModel.customMerchantConfidence)
                    .keyboardType(.decimalPad)

                TextField(String(localized: "Category Name"), text: $viewModel.customCategoryName)
                TextField(String(localized: "Category Icon"), text: $viewModel.customCategoryIcon)

                Picker(String(localized: "Category Type"), selection: $viewModel.customCategoryType) {
                    ForEach(viewModel.categoryTypeOptions, id: \.self) { option in
                        Text(option)
                    }
                }

                Button(String(localized: "Save Custom Records")) {
                    viewModel.createCustomRecords()
                    lastActionMessage = String(localized: "Saved custom records request executed.")
                }
            }

            Section(String(localized: "0.4 Repository Layer")) {
                Button(String(localized: "Run Repository Example")) {
                    viewModel.runRepositoryExample()
                    lastActionMessage = String(localized: "Repository check completed.")
                }
                Text(viewModel.repositoryOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.5 Merchant Resolver")) {
                Button(String(localized: "Resolve Merchant Example")) {
                    viewModel.runMerchantResolverExample()
                    lastActionMessage = String(localized: "Merchant resolver example completed.")
                }
                Text(viewModel.merchantResolverOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.6 Analytics Tracker")) {
                Button(String(localized: "Track Analytics Example")) {
                    viewModel.runAnalyticsExample()
                    lastActionMessage = String(localized: "Analytics example events tracked.")
                }
                Text(viewModel.analyticsOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.7 Initial Category Seeding")) {
                Button(String(localized: "Seed Categories")) {
                    viewModel.runSeedingExample()
                    lastActionMessage = String(localized: "Category seeding executed.")
                }
                Text(viewModel.seedingOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.8 iCloud Availability Check")) {
                Button(String(localized: "Check iCloud")) {
                    lastActionMessage = String(localized: "Checking iCloud availability...")
                    Task {
                        await viewModel.runICloudAvailabilityExample()
                        lastActionMessage = String(localized: "iCloud availability check completed.")
                    }
                }
                Text(viewModel.iCloudOutput)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section(String(localized: "0.9 Data Export (CSV/JSON)")) {
                Button(String(localized: "Generate Export Example")) {
                    viewModel.runExportExample()
                    lastActionMessage = String(localized: "Export example generated.")
                }
                Text(viewModel.exportOutput)
                    .font(.footnote)
                    .textSelection(.enabled)

                if !viewModel.csvPreview.isEmpty {
                    Text(viewModel.csvPreview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                if !viewModel.jsonPreview.isEmpty {
                    Text(viewModel.jsonPreview)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }

            Section(String(localized: "Data Browser")) {
                Button(String(localized: "Refresh Stored Data")) {
                    viewModel.refreshDataBrowser()
                    lastActionMessage = String(localized: "Data browser refreshed.")
                }

                Text(viewModel.dataBrowserOutput)
                    .font(.footnote)
                    .textSelection(.enabled)

                if !viewModel.accountRows.isEmpty {
                    Text(String(localized: "Accounts"))
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(viewModel.accountRows.enumerated()), id: \.offset) { _, row in
                        Text(row)
                            .font(.caption.monospaced())
                    }
                }

                if !viewModel.transactionRows.isEmpty {
                    Text(String(localized: "Transactions"))
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(viewModel.transactionRows.enumerated()), id: \.offset) { _, row in
                        Text(row)
                            .font(.caption.monospaced())
                    }
                }

                if !viewModel.merchantRows.isEmpty {
                    Text(String(localized: "Merchants"))
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(viewModel.merchantRows.enumerated()), id: \.offset) { _, row in
                        Text(row)
                            .font(.caption.monospaced())
                    }
                }

                if !viewModel.categoryRows.isEmpty {
                    Text(String(localized: "Categories"))
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(viewModel.categoryRows.enumerated()), id: \.offset) { _, row in
                        Text(row)
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .onAppear {
            viewModel.configure(context: context)
        }
        .onChange(of: context) { _, newContext in
            viewModel.configure(context: newContext)
        }
        .navigationTitle(String(localized: "Milestone 0 Examples"))
    }
}
