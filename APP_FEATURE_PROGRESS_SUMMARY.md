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
  - `MoneyManager/App/Services/DashboardDataService.swift` computes balances, cycle days, safe daily spend, category breakdown, recent transactions.
  - `MoneyManager/App/ViewModels/DashboardViewModel.swift` maps summary to UI state.
  - `MoneyManagerTests/DashboardViewModelTests.swift` validates mapping and cycle-based calculations.

### 5) Dashboard budget warning (weekly)
- Status: Ready (settings-driven)
- Evidence:
  - `MoneyManager/App/Extensions/DashboardViewModel+Insights.swift` now uses configurable warning/critical thresholds from settings.
  - `MoneyManager/App/Services/DashboardDataService.swift` reads settings and passes thresholds to dashboard summary.
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

### 10) Budget settings thresholds wired into dashboard
- Status: Ready
- Evidence:
  - `MoneyManager/App/UI/Screens/Settings/SettingsBudgetsDetailPage.swift` stores warning/critical thresholds.
  - `MoneyManager/App/Services/DashboardDataService.swift` observes settings changes and supplies threshold values.
  - `MoneyManager/App/Extensions/DashboardViewModel+Insights.swift` applies threshold values in alert derivation.

### 11) Category budgets integrated into dashboard alerts
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/DashboardDataService.swift` computes month category spend vs category budgets and adds budget alerts.
  - `MoneyManager/App/Services/CategoryBudgetService.swift` provides resolved monthly/default category budgets.
  - Alerts now show clearer warning/exceeded copy and surface up to three top budget issues.

### 12) Account auto-selection persistence and usage recording
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/AccountAutoSelectionService.swift` now persists and validates last-used account ID.
  - `MoneyManager/App/ViewModels/AddTransactionViewModel.swift` records account usage after successful save.

### 13) Amount typo prevention wired in app composition
- Status: Ready
- Evidence:
  - `MoneyManager/App/UI/Navigation/MilestoneOneRootView.swift` injects `TransactionErrorPreventionService` into `AddTransactionViewModel`.
  - `MoneyManager/App/ViewModels/AddTransactionViewModel.swift` evaluates high-amount warning through prevention service.

### 14) Notification scheduling backend for settings toggles
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/NotificationSchedulingService.swift` implements local notification scheduling + permission request flow.
  - `MoneyManager/App/UI/Screens/Settings/SettingsNotificationsDetailPage.swift` syncs all toggles with scheduler.
  - `MoneyManagerTests/NotificationSchedulingServiceTests.swift` validates scheduling/removal and permission-denied behavior.

### 15) Transaction undo in add transaction user flow
- Status: Ready
- Evidence:
  - `MoneyManager/App/ViewModels/AddTransactionViewModel.swift` records undoable saves and supports undo action.
  - `MoneyManager/App/UI/Screens/AddTransactionScreen.swift` displays undo row and triggers undo.
  - `MoneyManager/App/UI/Navigation/MilestoneOneRootView.swift` injects undo and mutation services.
  - `MoneyManagerTests/AddTransactionViewModelTests.swift` includes undo regression coverage.

### 16) Weekly budget projection no longer purely hard-coded
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/DashboardDomainServices.swift` now derives weekly budget from configured monthly budget when available.
  - `MoneyManager/App/Services/DashboardDataService.swift` reads `settings.defaultMonthlyBudget` for projection.
  - `MoneyManagerTests/DashboardViewModelTests.swift` includes configurable weekly projection test.

### 17) Income-independent financial state model
- Status: Ready
- Evidence:
  - `MoneyManager/App/Services/DashboardDataService.swift` now uses opening balance + remaining cycle days instead of salary timing.
  - `MoneyManager/App/Services/DashboardDomainServices.swift` projections use opening balance and cycle window inputs.
  - `MoneyManager/App/UI/Screens/Settings/SettingsAccountsAndIncomeDetailPage.swift` provides opening-balance setup and removes income-schedule dependency from the primary settings flow.
  - `MoneyManager/App/UI/Screens/Dashboard/DashboardFinancialStateCard.swift` uses cycle/reset language in user-facing copy.

## Partial (Exists but Not Fully Implemented/Wired)
None (for active, non-commented items in this document).

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

None (for active, non-commented items in this document).

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

## Hard-Coded / Development-Only Items To Note

- Dashboard weekly warning thresholds are now settings-driven via `settings.budgetWarningThreshold` and `settings.budgetCriticalThreshold`.
- Weekly budget projection now prefers configured monthly budget (`settings.defaultMonthlyBudget`) and falls back to historical heuristic when monthly budget is unset.
- Dummy transaction generation/deletion exists for testing in:
  - `MoneyManager/App/Services/DummyTransactionCRUDService.swift`
  - `MoneyManager/App/UI/Screens/Settings/SettingsAdvancedDetailPage.swift`

## Suggested Next Implementation Priorities

1. Add UI/integration tests that validate notification toggle behavior in Settings screen (not only service-level tests).
2. Add localization entries for new/updated budget alert phrases in all supported languages.
3. Monitor real user behavior and adjust fallback weekly-budget heuristic if needed.
<!-- 4. Decide whether Save tab should be enabled now or postponed.
5. Implement OCR/voice capture milestones or hide their source options until ready. -->