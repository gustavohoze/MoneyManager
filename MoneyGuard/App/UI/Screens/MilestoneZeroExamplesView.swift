import SwiftUI
import CoreData

struct MilestoneZeroExamplesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @StateObject private var viewModel = MilestoneZeroExamplesViewModel()
    @State private var toast: UniversalToastState?
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }
    
    private var developerSection: some View {
        Section(String(localized: "Developer")) {
            Button(String(localized: "Back to Milestone 1")) {
                showMilestoneZeroExamples = false
                toast = UniversalToastState(message: String(localized: "Returned to Milestone 1 app shell."))
            }
        }
    }
    
    private var storeStatusSection: some View {
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
                toast = UniversalToastState(message: persistenceStoreManager.requestCloudKitUpgrade().message)
            }
        }
    }
    
    private var projectStructureSection: some View {
        Section(String(localized: "0.1 Project Structure")) {
            Text(String(localized: "UI / ViewModels / Persistence / Repositories / Services / Extensions"))
                .font(.subheadline)
        }
    }
    
    var body: some View {
        List {
#if DEBUG
            developerSection
#endif
            
            storeStatusSection
            projectStructureSection
            persistenceSection
            coreDataSection
            customDataSection
            repositorySection
            merchantResolverSection
            analyticsSection
            seedingSection
            iCloudSection
            exportSection
            dataBrowserSection
        }
        .onAppear {
            viewModel.configure(context: context)
        }
        .onChange(of: context) { _, newContext in
            viewModel.configure(context: newContext)
        }
        .navigationTitle(String(localized: "Milestone 0 Examples"))
        .overlay(alignment: .bottom) {
            if let toast {
                UniversalToastView(
                    state: toast,
                    palette: palette,
                    onUndo: nil,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            self.toast = nil
                        }
                    }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: toast?.id)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(2.8))
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = nil
            }
        }
    }
    
    private var persistenceSection: some View {
        Section(String(localized: "0.2 Persistence Architecture")) {
            Button(String(localized: "Show Persistence Example")) {
                viewModel.showPersistenceExample()
                toast = UniversalToastState(message: String(localized: "Loaded persistence details."))
            }
            Text(viewModel.persistenceOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var coreDataSection: some View {
        Section(String(localized: "0.3 Core Data Entities")) {
            Button(String(localized: "Create Entity Examples")) {
                viewModel.runEntityExample()
                toast = UniversalToastState(message: String(localized: "Created sample entity records."))
            }
            Text(viewModel.entityOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var customDataSection: some View {
        Section(String(localized: "Custom Data Entry")) {
            TextField(String(localized: "Payment Method Name"), text: $viewModel.customAccountName)
            Picker(String(localized: "Payment Method Type"), selection: $viewModel.customAccountType) {
                ForEach(viewModel.accountTypeOptions, id: \.self) { option in
                    Text(option)
                }
            }
            TextField(String(localized: "Payment Method Currency"), text: $viewModel.customAccountCurrency)
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
                toast = UniversalToastState(message: String(localized: "Saved custom records request executed."))
            }
        }
    }
    
    private var repositorySection: some View {
        Section(String(localized: "0.4 Repository Layer")) {
            Button(String(localized: "Run Repository Example")) {
                viewModel.runRepositoryExample()
                toast = UniversalToastState(message: String(localized: "Repository check completed."))
            }
            Text(viewModel.repositoryOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var merchantResolverSection: some View {
        Section(String(localized: "0.5 Merchant Resolver")) {
            Button(String(localized: "Resolve Merchant Example")) {
                viewModel.runMerchantResolverExample()
                toast = UniversalToastState(message: String(localized: "Merchant resolver example completed."))
            }
            Text(viewModel.merchantResolverOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var analyticsSection: some View {
        Section(String(localized: "0.6 Analytics Tracker")) {
            Button(String(localized: "Track Analytics Example")) {
                viewModel.runAnalyticsExample()
                toast = UniversalToastState(message: String(localized: "Analytics example events tracked."))
            }
            Text(viewModel.analyticsOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var seedingSection: some View {
        Section(String(localized: "0.7 Initial Category Seeding")) {
            Button(String(localized: "Seed Categories")) {
                viewModel.runSeedingExample()
                toast = UniversalToastState(message: String(localized: "Category seeding executed."))
            }
            Text(viewModel.seedingOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var iCloudSection: some View {
        Section(String(localized: "0.8 iCloud Availability Check")) {
            Button(String(localized: "Check iCloud")) {
                toast = UniversalToastState(message: String(localized: "Checking iCloud availability..."))
                Task {
                    await viewModel.runICloudAvailabilityExample()
                    toast = UniversalToastState(message: String(localized: "iCloud availability check completed."))
                }
            }
            Text(viewModel.iCloudOutput)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }
    
    private var exportSection: some View {
        Section(String(localized: "0.9 Data Export (CSV/JSON)")) {
            Button(String(localized: "Generate Export Example")) {
                viewModel.runExportExample()
                toast = UniversalToastState(message: String(localized: "Export example generated."))
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
    }
    
    private var dataBrowserSection: some View {
        Section(String(localized: "Data Browser")) {
            Button(String(localized: "Refresh Stored Data")) {
                viewModel.refreshDataBrowser()
                toast = UniversalToastState(message: String(localized: "Data browser refreshed."))
            }
            
            Text(viewModel.dataBrowserOutput)
                .font(.footnote)
                .textSelection(.enabled)
            
            if !viewModel.accountRows.isEmpty {
                Text(String(localized: "Payment Methods"))
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
}
