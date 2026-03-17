import SwiftUI
import CoreData
import Combine

struct MilestoneOneRootView: View {
    private enum Tab: Hashable {
        case dashboard
        case transactions
        case add
        case settings
    }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var transactionListViewModel: TransactionListViewModel
    @StateObject private var addTransactionViewModel: AddTransactionViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var rootViewModel: MilestoneOneRootViewModel

    private let startupSeedingService: StartupSeedingService
    private let context: NSManagedObjectContext

    @State private var selectedTab: Tab = .dashboard

    init(context: NSManagedObjectContext) {
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let merchantResolver = MerchantResolver()
        let analytics = InMemoryAnalyticsService()

        let dashboardService = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )

        let transactionListService = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )

        let transactionMutationService = TransactionMutationService(
            transactionRepository: transactionRepository,
            merchantResolver: merchantResolver,
            analytics: analytics
        )

        let merchantMemoryService = MerchantMemoryService(
            merchantRepository: CoreDataMerchantRepository(context: context),
            categoryRepository: categoryRepository,
            merchantResolver: merchantResolver
        )

        let transactionEntryService = TransactionEntryService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            merchantResolver: merchantResolver,
            merchantMemoryRecorder: merchantMemoryService,
            analytics: analytics
        )

        let accountManagementService = AccountManagementService(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository,
            analytics: analytics
        )

        let dummyTransactionCRUDService = DummyTransactionCRUDService(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            categoryRepository: categoryRepository
        )

        let formOptionsService = TransactionFormOptionsService(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository
        )

        // MARK: - Milestone 2: Frictionless Expense Capture Services
        let accountAutoSelectionService = AccountAutoSelectionService(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository
        )

        let errorPreventionService = TransactionErrorPreventionService(
            transactionRepository: transactionRepository
        )

        let undoService = TransactionUndoService()

        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(dataProvider: dashboardService))
        _transactionListViewModel = StateObject(
            wrappedValue: TransactionListViewModel(
                dataProvider: transactionListService,
                mutationService: transactionMutationService,
                optionsProvider: formOptionsService
            )
        )
        let merchantSuggestionService = TransactionMerchantSuggestionService(
            transactionRepository: transactionRepository
        )

        _addTransactionViewModel = StateObject(
            wrappedValue: AddTransactionViewModel(
                transactionEntryService: transactionEntryService,
                optionsProvider: formOptionsService,
                merchantCategorySuggester: merchantMemoryService,
                merchantSuggestionProvider: merchantSuggestionService,
                accountAutoSelection: accountAutoSelectionService,
                undoService: undoService,
                merchantMemoryRecorder: merchantMemoryService
            )
        )
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(
                accountManager: accountManagementService,
                dummyTransactionManager: dummyTransactionCRUDService
            )
        )
        _rootViewModel = StateObject(wrappedValue: MilestoneOneRootViewModel())

        startupSeedingService = StartupSeedingService(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository
        )
        self.context = context
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardScreen(
                viewModel: dashboardViewModel,
                onSelectTransaction: { transactionID in
                    transactionListViewModel.beginEdit(id: transactionID)
                }
            )
                .tabItem {
                    Label(String(localized: "Dashboard"), systemImage: "chart.pie.fill")
                }
                .tag(Tab.dashboard)

            TransactionListScreen(viewModel: transactionListViewModel)
                .tabItem {
                    Label(String(localized: "Transactions"), systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.transactions)

            AddTransactionScreen(viewModel: addTransactionViewModel)
                .tabItem {
                    Label(String(localized: "Add"), systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)

            SettingsScreen(viewModel: settingsViewModel)
                .tabItem {
                    Label(String(localized: "Settings"), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(FinanceTheme.palette(for: colorScheme).accent)
        .sheet(item: $transactionListViewModel.editState) { state in
            TransactionEditSheetView(
                state: state,
                onCancel: { transactionListViewModel.cancelEdit() },
                onSave: { draft in transactionListViewModel.saveEdit(draft: draft) }
            )
        }
        .task {
            guard !rootViewModel.hasLoaded else {
                return
            }

            rootViewModel.markLoaded()

            do {
                try startupSeedingService.seedMilestoneOneDefaults()
            } catch {
                // Intentionally ignored in UI bootstrap; individual screens expose errors.
            }

            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
                .receive(on: RunLoop.main)
        ) { notification in
            guard rootViewModel.hasLoaded else {
                return
            }

            if rootViewModel.includesEntity(named: "Transaction", in: notification) {
                dashboardViewModel.load()
                transactionListViewModel.load()
            }

            if rootViewModel.includesEntity(named: "PaymentMethod", in: notification)
                || rootViewModel.includesEntity(named: "Category", in: notification)
            {
                addTransactionViewModel.loadOptions()
            }
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: .NSPersistentStoreRemoteChange)
                .receive(on: RunLoop.main)
        ) { _ in
            guard rootViewModel.hasLoaded else {
                return
            }

            // Ensure CloudKit-merged changes are reflected immediately in all milestone-one screens.
            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
                .receive(on: RunLoop.main)
        ) { notification in
            guard rootViewModel.hasLoaded else {
                return
            }

            guard rootViewModel.shouldRefreshForCloudKitEvent(notification) else {
                return
            }

            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard rootViewModel.hasLoaded, newPhase == .active else {
                return
            }

            // Lightweight foreground refresh: update visible data only, never rebuild persistence stack.
            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
        }
    }
}
