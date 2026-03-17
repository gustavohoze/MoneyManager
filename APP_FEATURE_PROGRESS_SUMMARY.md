# MoneyManager Feature Progress Summary

Last reviewed: 2026-03-18

This document summarizes which features are already working, which are partially implemented, and which still need implementation.

## Ready (Implemented and Wired)

### 1) Core app architecture and data flow
- Status: Ready
- Evidence:
  - `MoneyManager/App/UI/Navigation/MilestoneOneRootView.swift` wires repositories, services, and ViewModels.
  - `MoneyManager/App/Persistence/CoreDataStack/PersistenceController.swift` configures Core Data with CloudKit-capable container.

### 2) Transaction entry and CRUD flow
- Status: Ready
- Evidence:
  - `MoneyManager/App/ViewModels/AddTransactionViewModel.swift` supports form loading, validation, and save flow.
  - `MoneyManager/App/Services/TransactionEntryService.swift` handles transaction save logic.
  - `MoneyManager/App/Services/TransactionMutationService.swift` handles update/delete.
  - `MoneyManagerTests/AddTransactionViewModelTests.swift`, `MoneyManagerTests/TransactionEntryServiceTests.swift`, `MoneyManagerTests/TransactionListViewModelTests.swift` validate behavior.

### 3) Transaction timeline screen (month/week/day grouping)
- Status: Ready
- Evidence:
  - `MoneyManager/App/ViewModels/TransactionListViewModel.swift` builds timeline presentation (calendar strip, time buckets, category filter).
  - `MoneyManagerTests/TransactionListViewModelTests.swift` covers grouping, filtering, edit/delete flows.

### 4) Dashboard summary calculations
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/DashboardDataService.swift` computes balances, safe daily spend, category breakdown, recent transactions.
  - `MoneyManager/App/ViewModels/DashboardViewModel.swift` maps summary to UI state.
  - `MoneyManagerTests/DashboardViewModelTests.swift` validates mapping and salary schedule calculations.

### 5) Dashboard budget warning (weekly)
- Status: Ready (implemented, but currently fixed threshold)
- Evidence:
  - `MoneyManager/App/Extensions/DashboardViewModel+Insights.swift` adds warning at >=80% and exceeded at >=100% weekly usage.
  - `MoneyManagerTests/DashboardViewModelTests.swift` contains test `derivedAlerts_whenWeeklyProgressAboveEightyPercent_includesBudgetWarning`.

### 6) Merchant memory and suggestions
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/MerchantMemoryService.swift`
  - `MoneyManager/App/Services/TransactionMerchantSuggestionService.swift`
  - `MoneyManagerTests/MerchantMemoryServiceTests.swift`

### 7) Payment method and category management
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/AccountManagementService.swift`
  - `MoneyManager/App/Repositories/CoreDataRepositories.swift` (category upsert/dedup behavior)
  - `MoneyManagerTests/AccountManagementServiceTests.swift`, `MoneyManagerTests/RepositoryTests.swift`

### 8) Data export service (logic level)
- Status: Ready at service level
- Evidence:
  - `MoneyManager/App/Services/ExportService.swift`
  - `MoneyManagerTests/ExportServiceTests.swift`

### 9) CloudKit/iCloud availability and sync plumbing
- Status: Ready in infrastructure
- Evidence:
  - `MoneyManager/App/Persistence/CloudKitConfig/CloudKitConstants.swift`
  - `MoneyManager/App/Services/ICloudAvailabilityService.swift`
  - `MoneyManager/ContentView.swift` and `MoneyManager/App/Persistence/CoreDataStack/PersistenceStoreManager.swift` include upgrade/retry flow.

## Partial (Exists but Not Fully Implemented/Wired)

### 1) Budget settings thresholds are not connected to dashboard warnings
- Status: Partial
- Current behavior:
  - User can edit warning/critical thresholds in settings UI.
  - Dashboard warning logic still uses fixed values (80%/100%).
- Evidence:
  - Settings UI: `MoneyManager/App/UI/Screens/Settings/SettingsBudgetsDetailPage.swift`
  - Fixed logic: `MoneyManager/App/Extensions/DashboardViewModel+Insights.swift`

### 2) Category budget feature is implemented in Transactions flow, but not driving dashboard warnings
- Status: Partial
- Current behavior:
  - Budgets can be saved and shown in transaction month insights.
  - Dashboard alerting does not use category budgets yet (uses weekly projection ratio instead).
- Evidence:
  - Storage/service: `MoneyManager/App/Services/CategoryBudgetService.swift`
  - VM integration: `MoneyManager/App/ViewModels/TransactionListViewModel.swift`
  - Test: `MoneyManagerTests/CategoryBudgetServiceTests.swift`

### 3) Account auto-selection is only half-implemented
- Status: Partial
- Current behavior:
  - Last used account can be inferred from most recent transaction.
  - Recording account usage is TODO/empty implementation.
- Evidence:
  - `MoneyManager/App/Services/AccountAutoSelectionService.swift` (`recordAccountUsage` has future implementation comment)

### 4) Amount typo prevention service exists but is not fully wired in app composition
- Status: Partial
- Current behavior:
  - `TransactionErrorPreventionService` exists.
  - `AddTransactionViewModel` supports warning hooks.
  - Root composition currently does not pass `errorPrevention` into `AddTransactionViewModel`.
- Evidence:
  - Service: `MoneyManager/App/Services/TransactionErrorPreventionService.swift`
  - VM hooks: `MoneyManager/App/ViewModels/AddTransactionViewModel.swift`
  - Root wiring: `MoneyManager/App/UI/Navigation/MilestoneOneRootView.swift`

<!-- ### 5) Save Planning feature exists but tab is currently disabled in navigation
- Status: Partial
- Current behavior:
  - ViewModel, service, and screen exist.
  - Save tab is commented out in main TabView.
- Evidence:
  - Screen: `MoneyManager/App/UI/Screens/Save/SaveScreen.swift`
  - VM/service: `MoneyManager/App/ViewModels/SavePlanningViewModel.swift`, `MoneyManager/App/Services/SavingPlanService.swift`
  - Disabled tab: `MoneyManager/App/UI/Navigation/MilestoneOneRootView.swift` -->

## Not Implemented (or Only Placeholder UI)

### 1) Notification engine behind notification settings
- Status: Not implemented
- Current behavior:
  - Notification toggles exist in settings.
  - No scheduling/authorization integration found (`UNUserNotificationCenter` usage not present).
- Evidence:
  - UI toggles: `MoneyManager/App/UI/Screens/Settings/SettingsNotificationsDetailPage.swift`

<!-- ### 2) Voice logging capture flow
- Status: Not implemented
- Current behavior:
  - Source enum/options include `voice`, but no speech capture pipeline found.
- Evidence:
  - Allowed source values: `MoneyManager/App/Repositories/CoreDataRepositories.swift`
  - No speech APIs found in app source.

### 3) OCR capture/import flow (receipt OCR, bank OCR)
- Status: Not implemented
- Current behavior:
  - Source values include `bank_ocr` and `receipt_ocr`, but no OCR pipeline/services were found.
- Evidence:
  - Allowed source values: `MoneyManager/App/Repositories/CoreDataRepositories.swift`
  - No Vision/VisionKit OCR processing flow found in app source. -->

### 4) Transaction undo behavior in user flow
- Status: Not implemented in main flow
- Current behavior:
  - Undo service/UI component exists, but not integrated into add transaction user flow.
- Evidence:
  - Service: `MoneyManager/App/Services/TransactionUndoService.swift`
  - UI component: `MoneyManager/App/UI/Screens/AddTransaction/AddTransactionUndoRow.swift`

## Hard-Coded / Development-Only Items To Note

- Dashboard weekly warning thresholds are hard-coded in `MoneyManager/App/Extensions/DashboardViewModel+Insights.swift`.
- Weekly budget projection currently uses formula `max(weeklySpending, lastWeekSpending, 1) * 1.2` in `MoneyManager/App/Services/DashboardDomainServices.swift`.
- Dummy transaction generation/deletion exists for testing in:
  - `MoneyManager/App/Services/DummyTransactionCRUDService.swift`
  - `MoneyManager/App/UI/Screens/Settings/SettingsAdvancedDetailPage.swift`

## Suggested Next Implementation Priorities

1. Wire settings budget thresholds into dashboard warning logic.
2. Implement notification scheduler and permission flow for current toggles.
3. Finish account usage tracking (`recordAccountUsage`) and wire typo-prevention service from root.
<!-- 4. Decide whether Save tab should be enabled now or postponed.
5. Implement OCR/voice capture milestones or hide their source options until ready. -->