# MoneyManager App Store Release Inputs

Last updated: 2026-03-18

## Release Readiness Verdict (Current)

Status: CONDITIONAL GO (engineering quality gate passed; App Store content/compliance items still pending).

Resolved blocker:
- Payment method update currency bug fixed in service layer.
- Full test suite now passes.

What passed:
- Release device build succeeds (Release configuration, generic iOS destination).
- No editor diagnostics errors found across workspace.
- Full simulator test suite succeeded.

Non-blocking technical warnings to track:
- Xcode tool warning from appintentsmetadataprocessor: "Metadata extraction skipped. No AppIntents.framework dependency found." This is tooling-level and not a source warning.

---

## App Store Connect Information Checklist

Use this as the single input sheet before creating the App Store version.

### 1) App Record (One-time)

- App Name: MoneyManager
- Primary Language: English (confirm in App Store Connect)
- Bundle ID: shecraa.MoneyManager
- SKU: TBD (create unique internal identifier)
- Primary Category: Finance (recommended)
- Secondary Category: Productivity or Utilities (optional, decide)
- Content Rights: confirm all assets/icons/text are owned or licensed

### 2) Version Metadata (Per release)

- Version String (CFBundleShortVersionString / MARKETING_VERSION): 1.0
- Build Number (CFBundleVersion / CURRENT_PROJECT_VERSION): 1
- What is New in This Version: TBD
- Subtitle (30 chars max): Track spending, hit budgets
- Promotional Text (optional): Track spending in seconds, stay on budget with clear monthly insights, and keep your data private with Face ID and secure iCloud sync.
- Keywords (100 chars max): expense tracker,budget planner,money guard,personal finance,spending tracker,bill tracker
- App Description: MoneyManager helps you track daily spending, stay on top of budgets, and understand your money at a glance. Quickly add transactions, review your timeline, and monitor category trends with clear monthly insights. Your data stays under your control with secure storage, iCloud sync across devices, and optional Face ID protection.
- Support URL: https://shecraa.com/moneymanager/support (required)
- Marketing URL: optional (TBD)
- Copyright: TBD

### 3) Pricing and Availability

- Price Tier: TBD (Free recommended for v1 if no IAP)
- Availability Countries/Regions: Global (all available App Store territories); GeoJSON: AppStore/supported_regions.geojson
- App Distribution Method: Public or unlisted/private (TBD)
- App Store Distribution Date: TBD

### 4) App Privacy (Required)

You must complete the privacy questionnaire in App Store Connect.

Observed from codebase/integrations:
- Analytics backend configured via Supabase URL/table in Info.plist.
- Event payload appears to include user_id, session_id, event_name, timestamp, and properties.
- Local storage and iCloud/CloudKit are used for app data sync.
- Face ID usage is declared.

Decisions needed for privacy labels:
- Data types collected (usage data, identifiers, diagnostics, etc.): TBD by policy owner
- Is data linked to user identity?: TBD
- Is data used for tracking across apps/sites?: likely No, confirm
- Data retention policy and deletion process: TBD
- Privacy Policy URL (required): https://drive.google.com/file/d/REPLACE_WITH_FILE_ID/view (from AppStore/PRIVACY_POLICY_README.md)

### 5) Age Rating and Content Declarations

- Age Rating questionnaire answers:
  - Parental Controls: NO
  - Age Assurance: NO
  - Unrestricted Web Access: NO
  - User-Generated Content: NO
  - Messaging and Chat: NO
  - Advertising: NO
- Gambling/contests/medical content declarations: NO

### 6) Export Compliance

- Uses encryption: Yes (standard iOS HTTPS/TLS).
- Encryption algorithm type selection: None of the algorithms mentioned above.
- Export compliance answer usually: uses exempt encryption only (confirm legal/compliance response in ASC form).
- If custom/non-exempt crypto is used, provide documentation (TBD if applicable).

### 7) App Review Information (Required)

- Contact first name/last name: TBD
- Contact email and phone: TBD
- Demo account credentials: Not required (no account/login flow)
- Special instructions for reviewer: On first launch, allow notifications when prompted to validate reminder behavior. You can fully test core flows without creating an account.
- Notes for hardware dependencies (Face ID, notifications): include test flow instructions

### 8) Media Assets (Required)

- App Icon 1024x1024: present in asset catalog
- iPhone screenshots (required sizes for currently supported devices): TBD to capture
- iPad screenshots: TBD only if iPad supported in App Store record
- App Preview videos (optional): TBD

Recommended screenshot set for v1:
- Dashboard overview
- Add transaction flow
- Transaction timeline
- Category/budget insights
- Settings privacy/sync controls

### 9) Functional and Policy Checks Before Submission

- All tests green on CI/local: PASSING locally
- Manual smoke test on clean install: TBD
- Upgrade test from previous build: TBD
- Offline behavior sanity check: TBD
- Notification permission and behavior check: TBD
- Face ID lock/unlock flow check: TBD
- CloudKit sync sign-in/sign-out behavior check: TBD
- Localization QA for listed languages: TBD
- Accessibility smoke test (Dynamic Type, VoiceOver, contrast): TBD

### 10) Signing and Capability Snapshot (Current)

- Team ID: LCKK5B35FW
- iOS deployment target: 17.6
- Entitlements include:
  - CloudKit containers: iCloud.shecraa.MoneyManager
  - iCloud services: CloudKit
  - Push entitlement present (aps-environment)
- Info.plist permission strings include:
  - NSFaceIDUsageDescription
  - UIBackgroundModes: remote-notification

---

## Pre-Submission Go/No-Go Gate

Release can move to GO when all are true:
- Full suite passes consistently on local and CI.
- App Store metadata completed (description, keywords, support URL, privacy policy URL, release notes).
- Privacy questionnaire completed and aligned with actual data flows.
- Required screenshots captured and uploaded.
- Final manual QA pass completed on at least one physical device and one clean simulator install.

## Owner Fill-In Section

Use this section to fill final values quickly:
- SKU:
- Support URL: https://shecraa.com/moneymanager/support
- Privacy Policy URL: https://drive.google.com/file/d/REPLACE_WITH_FILE_ID/view
- Marketing URL:
- Copyright:
- Price Tier:
- Countries/Regions: Global (all available App Store territories); GeoJSON: AppStore/supported_regions.geojson
- What is New:
- Subtitle: Track spending, hit budgets
- Promotional Text: Track spending in seconds, stay on budget with clear monthly insights, and keep your data private with Face ID and secure iCloud sync.
- App Description: MoneyManager helps you track daily spending, stay on top of budgets, and understand your money at a glance. Quickly add transactions, review your timeline, and monitor category trends with clear monthly insights. Your data stays under your control with secure storage, iCloud sync across devices, and optional Face ID protection.
- Keywords: expense tracker,budget planner,money guard,personal finance,spending tracker,bill tracker
- Review Contact:
- Review Notes: No sign-in is required. Test flow: (1) Add a transaction from the Add screen, (2) edit and delete from the transaction timeline, (3) verify dashboard totals and category insights update immediately, (4) open Settings to test Face ID lock toggle and notification preferences. For notification checks, grant notification permission on first launch. iCloud/CloudKit sync is enabled when the device is signed into iCloud; if not signed in, local usage remains fully functional.
