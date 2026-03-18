import SwiftUI
import CoreData
import Combine

struct MilestoneOneRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var transactionListViewModel: TransactionListViewModel
    @StateObject private var addTransactionViewModel: AddTransactionViewModel
    @StateObject private var savePlanningViewModel: SavePlanningViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var rootViewModel: MilestoneOneRootViewModel

    private let startupSeedingService: StartupSeedingService
    private let analytics: AnalyticsTracking
    private let appUsageAnalytics: AppUsageAnalyticsService
    private let context: NSManagedObjectContext
    private let autoFocusAddAmountOnLaunch: Bool
    private let onInitialLaunchHandled: (() -> Void)?

    @State private var selectedTab: MilestoneOneTab = .dashboard

    init(
        context: NSManagedObjectContext,
        initialTab: MilestoneOneTab = .dashboard,
        autoFocusAddAmountOnLaunch: Bool = false,
        onInitialLaunchHandled: (() -> Void)? = nil
    ) {
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let merchantResolver = MerchantResolver()
        let analytics = AnalyticsServiceFactory.makeDefault()
        let appUsageAnalytics = AppUsageAnalyticsService(analytics: analytics)
        let dashboardSettingsProvider = UserDefaultsDashboardSettingsProvider()
        let dashboardRefreshTrigger = UserDefaultsDashboardRefreshTrigger()
        let categoryBudgetService = UserDefaultsCategoryBudgetService()

        let dashboardService = DashboardDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository,
            settingsProvider: dashboardSettingsProvider,
            budgetProvider: categoryBudgetService
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

        let paymentMethodManagementService = PaymentMethodManagementService(
            paymentMethodRepository: accountRepository,
            transactionRepository: transactionRepository,
            analytics: analytics
        )

        let savingPlanService = SavingPlanService(
            repository: CoreDataSavingPlanRepository(context: context)
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

        _dashboardViewModel = StateObject(
            wrappedValue: DashboardViewModel(
                dataProvider: dashboardService,
                refreshTrigger: dashboardRefreshTrigger
            )
        )
        _transactionListViewModel = StateObject(
            wrappedValue: TransactionListViewModel(
                dataProvider: transactionListService,
                mutationService: transactionMutationService,
                optionsProvider: formOptionsService,
                budgetProvider: categoryBudgetService
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
                errorPrevention: errorPreventionService,
                merchantMemoryRecorder: merchantMemoryService,
                undoService: undoService,
                mutationService: transactionMutationService
            )
        )
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(
                paymentMethodManager: paymentMethodManagementService,
                dummyTransactionManager: dummyTransactionCRUDService,
                optionsProvider: formOptionsService
            )
        )
        _savePlanningViewModel = StateObject(wrappedValue: SavePlanningViewModel(planManager: savingPlanService))
        _rootViewModel = StateObject(wrappedValue: MilestoneOneRootViewModel())

        startupSeedingService = StartupSeedingService(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository
        )
        self.analytics = analytics
        self.appUsageAnalytics = appUsageAnalytics
        self.context = context
        self.autoFocusAddAmountOnLaunch = autoFocusAddAmountOnLaunch
        self.onInitialLaunchHandled = onInitialLaunchHandled
        _selectedTab = State(initialValue: initialTab)
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
                .tag(MilestoneOneTab.dashboard)

            TransactionListScreen(viewModel: transactionListViewModel)
                .tabItem {
                    Label(String(localized: "Transactions"), systemImage: "list.bullet.rectangle")
                }
                .tag(MilestoneOneTab.transactions)

            AddTransactionScreen(
                viewModel: addTransactionViewModel,
                autoFocusAmountOnAppear: autoFocusAddAmountOnLaunch
            )
                .tabItem {
                    Label(String(localized: "Add"), systemImage: "plus.circle.fill")
                }
                .tag(MilestoneOneTab.add)

//            SaveScreen(viewModel: savePlanningViewModel)
//                .tabItem {
//                    Label(String(localized: "Save"), systemImage: "banknote.fill")
//                }
//                .tag(MilestoneOneTab.save)

            SettingsScreen(viewModel: settingsViewModel)
                .tabItem {
                    Label(String(localized: "Settings"), systemImage: "gearshape.fill")
                }
                .tag(MilestoneOneTab.settings)
        }
        .tint(FinanceTheme.palette(for: colorScheme).accent)
        .sheet(item: $transactionListViewModel.editState) { state in
            TransactionEditSheetView(
                state: state,
                onCancel: { transactionListViewModel.cancelEdit() },
                onSave: { draft in transactionListViewModel.saveEdit(draft: draft) },
                onDelete: {
                    transactionListViewModel.cancelEdit()
                    transactionListViewModel.deleteTransaction(id: state.id)
                }
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

            appUsageAnalytics.appDidLaunch()
            appUsageAnalytics.sessionDidBecomeActive()
            appUsageAnalytics.didSelectFeature(selectedTab)

            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
            savePlanningViewModel.load()
            onInitialLaunchHandled?()
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

            if rootViewModel.includesEntity(named: "SavingPlan", in: notification) {
                savePlanningViewModel.load()
            }

            if rootViewModel.includesEntity(named: "Account", in: notification)
                || rootViewModel.includesEntity(named: "PaymentMethod", in: notification)
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
            savePlanningViewModel.load()
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
            savePlanningViewModel.load()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard rootViewModel.hasLoaded, newPhase == .active else {
                if rootViewModel.hasLoaded,
                   newPhase == .inactive || newPhase == .background {
                    appUsageAnalytics.sessionDidEnd()
                    analytics.flush(completion: nil)
                }
                return
            }

            appUsageAnalytics.sessionDidBecomeActive()
            appUsageAnalytics.didSelectFeature(selectedTab)

            // Lightweight foreground refresh: update visible data only, never rebuild persistence stack.
            addTransactionViewModel.loadOptions()
            dashboardViewModel.load()
            transactionListViewModel.load()
            savePlanningViewModel.load()
        }
        .onChange(of: selectedTab) { _, newTab in
            guard rootViewModel.hasLoaded else {
                return
            }

            appUsageAnalytics.didSelectFeature(newTab)
        }
    }
}
