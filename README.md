# MoneyManager (iOS)

MoneyManager is an iOS-first, privacy-first personal finance tracker built with **SwiftUI + Core Data + CloudKit**.

Financial data is stored locally and can sync via the user’s iCloud account (no custom backend required), keeping infrastructure cost extremely low while still supporting multi-device sync.

## Highlights

- **SwiftUI app architecture** with clear separation of concerns (Views → ViewModels → Services/Repositories → Persistence)
- **Core Data as the local source of truth** with CloudKit-enabled persistence for optional iCloud sync
- **Expense tracking workflow**: add/edit/delete transactions, timeline grouping (day/week/month), and dashboard summaries
- **Budgeting & insights**: weekly budget progress warnings and category budget alerts driven by settings
- **Quality focus**: service + ViewModel test coverage for core flows (transactions, dashboard calculations, export, notifications)

## Key Features (Implemented)

- Transaction CRUD (create / edit / delete)
- Dashboard: balances, recent transactions, category breakdown, cycle-based calculations
- Merchant memory & suggestions
- Payment method + category management
- Data export service (**CSV/JSON**) at the service layer
- Local notification scheduling for reminders (settings-driven)
- iCloud availability checks + CloudKit sync plumbing

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Persistence:** Core Data (`NSPersistentCloudKitContainer`)
- **Sync:** CloudKit (via iCloud)
- **Testing:** XCTest

## Project Structure (High level)

```text
UI (SwiftUI Screens)
  ↓
ViewModels
  ↓
Services + Repositories
  ↓
Core Data (local source of truth)
  ↓
CloudKit sync (optional, via iCloud)
```

For more detail, see: `Architecture.md`.

## Getting Started

1. Clone the repo
2. Open the Xcode project: `Money Guard.xcodeproj`
3. Select a simulator or device
4. Run

> Note: CloudKit sync requires iCloud to be enabled on the device/simulator and the app’s entitlements to be configured correctly.

## Privacy

This project is designed to be **privacy-first**:

- Financial records are stored on-device via Core Data
- If iCloud is enabled, data syncs via the user’s iCloud/CloudKit account
- No transaction amounts/merchant details are intended to be sent to external analytics services

## Roadmap

The repo includes planning docs (e.g., `PRD.md`) describing future capture methods such as voice logging and OCR import flows.

## License

No license file is currently included. If you plan to open-source this project, consider adding an OSI-approved license (e.g., MIT).
