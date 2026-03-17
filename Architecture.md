Good request. A roadmap without **acceptance criteria** turns into vague “it works on my device” development. Proper QA criteria will force each milestone to be **objectively testable**.

We’ll do this in two parts:

1️⃣ **System architecture overview** (how everything fits together)
2️⃣ **Acceptance criteria per milestone** (what QA must verify)

This reply will cover **architecture + QA for Milestone 0 and 1**. Later replies can cover the rest in detail.

---

# System Architecture (High Level)

Your app architecture should look like this:

```text
UI Layer
│
├── Screens (SwiftUI Views)
│
├── ViewModels
│
├── Coordniator
│
├── Services
│   ├── OCRService
│   ├── MerchantResolver
│   ├── InsightsEngine
│   └── AnalyticsService
│
├── Repositories
│   ├── TransactionRepository
│   ├── MerchantRepository
│   ├── PaymentMethodRepository
│   └── CategoryRepository
│
├── Persistence
│   └── CoreDataStack (CloudKit enabled)
│
└── Extensions
    ├── ShareExtension (bank screenshots)
    └── ReceiptScanner
    └── Localization
```

Frameworks used in the architecture:

* SwiftUI
* Core Data
* CloudKit
* Apple Vision Framework
* VisionKit
* App Intents

Important architectural rule:

```
UI never talks directly to Core Data
```

Everything must pass through **repositories**.

---

# Milestone 0 — Acceptance Criteria (QA)

Milestone 0 is infrastructure, so QA verifies **data reliability**.

### Core Data initialization

Test cases:

```
Launch app first time
```

Expected result:

```
Default categories created
Default PaymentMethods created
Database initialized
```

---

### CloudKit sync

Test steps:

```
Device A: create transaction
Device B: login same Apple ID
Open app
```

Expected:

```
Transaction appears on Device B
```

Failure criteria:

```
Transaction not synced after 10 seconds
```

---

### Offline mode

Test:

```
Disable internet
Create transaction
Enable internet
```

Expected:

```
Transaction syncs automatically
```

---

### Data persistence

Test:

```
Add 10 transactions
Force close app
Reopen app
```

Expected:

```
All transactions still exist
```

---

### App reinstall test

Steps:

```
Create transactions
Delete app
Reinstall app
Login Apple ID
```

Expected:

```
Data restored from CloudKit
```

---

# Milestone 1 — Acceptance Criteria (QA)

Milestone 1 validates **basic finance tracking**.

---

## Manual transaction creation

Test:

```
Open Add Transaction
Enter amount
Enter merchant
Save
```

Expected:

```
Transaction appears in list
Dashboard updates
```

---

## Required field validation

Test:

```
Leave amount empty
Press save
```

Expected:

```
Validation error shown
Transaction not saved
```

---

## Transaction editing

Test:

```
Edit merchant name
Save
```

Expected:

```
Transaction updated immediately
```

---

## Transaction deletion

Test:

```
Delete transaction
```

Expected:

```
Transaction removed
Dashboard recalculates totals
```

---

## Dashboard totals

Test dataset:

```
Income: 1,000
Expense: 200
Expense: 300
```

Expected balance:

```
500
```

Calculation must match.

---

## Category assignment

Test:

```
Assign category Food
Save
```

Expected:

```
Category displayed correctly
```

---

## Merchant memory

Test:

```
Transaction 1: Grab → Transport
Transaction 2: Grab
```

Expected:

```
Category auto-filled as Transport
```

---

## Transaction sorting

Test dataset:

```
Transaction A: today
Transaction B: yesterday
```

Expected order:

```
today
yesterday
```

---

## Data export

Test:

```
Export CSV
```

Expected:

```
CSV contains all transactions
Fields correct
```

Example row:

```
2026-03-15,Starbucks,45000,Food,BCA
```

---

# QA Test Coverage Checklist

Milestone 1 QA checklist:

```
Transaction creation
Transaction editing
Transaction deletion
Dashboard totals
Merchant memory
Category assignment
Sorting logic
Data export
CloudKit sync
Offline persistence
```

---

# What QA should deliberately try to break

Encourage testers to try:

```
Very large numbers
Negative amounts
Weird merchant names
Rapid transaction creation
Deleting large data sets
```

Your system must remain stable.

---

Good. Now we move to **QA acceptance criteria for the complex milestones**: Milestone 2 (Fast Capture), Milestone 3 (OCR), Milestone 4 (Merchant Intelligence), and Milestone 5 (Insights). These require much stricter testing because they involve **automation, ML-like behavior, and edge cases**.

---

# Milestone 2 — QA Acceptance Criteria

Fast Capture System

Framework used:

* App Intents

Goal: transaction logging must take **under 2–3 seconds**.

---

# 2.1 Quick Add Button

Test steps:

```text
Open Dashboard
Tap "+"
Enter amount
Enter merchant
Save
```

Expected:

```text
Transaction saved within 2 seconds
Dashboard updated
Transaction appears in list
```

Performance acceptance:

```text
Quick Add flow < 3 seconds
```

---

# 2.2 Merchant auto-complete

Test:

```text
Create transaction with merchant: Starbucks
Create second transaction
Type: "Sta"
```

Expected:

```text
Starbucks appears as suggestion
Selecting suggestion autofills merchant
```

Failure:

```text
Suggestion list empty
```

---

# 2.3 Voice logging (Siri)

Voice command:

```text
"Log 50k coffee"
```

Expected result:

```text
Transaction created
amount = 50000
merchant = coffee
```

Test additional phrases:

```text
"Add 100k groceries"
"Record 20k Grab ride"
```

All must parse correctly.

---

# 2.4 Voice ambiguity handling

Test phrase:

```text
"Log coffee"
```

Expected behavior:

```text
System asks for amount
```

Failure:

```text
Transaction saved with missing amount
```

---

# 2.5 Siri confirmation

After voice logging:

Expected response:

```text
"Added 50,000 for coffee."
```

---

# 2.6 Lock screen logging

Test:

```text
Trigger quick logging from lock screen widget
Add transaction
```

Expected:

```text
Transaction saved successfully
```

---

# Milestone 2 success criteria

✔ Voice commands create transactions
✔ Quick Add < 3 seconds
✔ Merchant suggestions appear
✔ Lock screen logging works

---

# Milestone 3 — QA Acceptance Criteria

OCR Import System

Frameworks:

* Apple Vision Framework
* VisionKit
* Share Extensions

This milestone needs **image testing datasets**.

---

# 3.1 Bank screenshot OCR

Test images:

```text
Bank transaction screenshot
```

Expected extraction:

```text
merchant
amount
date
```

Acceptance threshold:

```text
>80% correct extraction
```

Example:

Input screenshot text:

```text
GRAB *TRIP
9000 DB
```

Expected:

```text
merchant = Grab
amount = 9000
```

---

# 3.2 Share extension workflow

Test:

```text
Take screenshot
Tap Share
Select app
```

Expected:

```text
OCR result preview appears
```

Performance acceptance:

```text
Processing time < 2 seconds
```

---

# 3.3 Receipt scanning

Framework used:

* VisionKit

Test:

```text
Scan printed receipt
```

Expected extraction:

```text
merchant
total
date
```

Example:

Input:

```text
STARBUCKS
TOTAL 82,500
```

Expected:

```text
merchant = Starbucks
amount = 82500
```

---

# 3.4 OCR failure handling

Test with:

```text
blurry image
dark screenshot
cropped receipt
```

Expected:

```text
User can manually edit OCR result
```

System must never crash.

---

# 3.5 Duplicate detection

Test:

```text
Import screenshot
Import same screenshot again
```

Expected:

```text
Duplicate warning shown
```

---

# Milestone 3 success criteria

✔ Share extension receives screenshots
✔ OCR extracts transaction data
✔ Receipt scanning works
✔ Duplicate detection works

---

# Milestone 4 — QA Acceptance Criteria

Merchant Intelligence

Frameworks:

* Core ML
* Natural Language Framework

---

# 4.1 Merchant normalization

Test input:

```text
STARBUCKS RESERVE
STARBUCKS JKT
```

Expected output:

```text
Starbucks
```

All variants map to same merchant.

---

# 4.2 Category prediction

Test:

```text
Merchant: Starbucks
```

Expected:

```text
Category: Food
```

---

# 4.3 User correction learning

Test:

```text
Change category Grab → Transport
Add new Grab transaction
```

Expected:

```text
Category auto-filled as Transport
```

---

# 4.4 Unknown merchant

Test:

```text
Merchant: random store
```

Expected:

```text
System suggests categories
```

Must not auto-categorize with low confidence.

---

# Milestone 4 success criteria

✔ merchants normalized
✔ categories predicted
✔ corrections remembered

Target accuracy:

```text
>85%
```

---

# Milestone 5 — QA Acceptance Criteria

Financial Insights

---

# 5.1 Weekly summary

Test dataset:

```text
3 transactions totaling 500k this week
```

Expected insight:

```text
"You spent Rp500,000 this week."
```

---

# 5.2 Category analysis

Test dataset:

```text
Food 200k
Transport 100k
Groceries 300k
```

Expected ranking:

```text
Groceries
Food
Transport
```

---

# 5.3 Subscription detection

Test data:

```text
Netflix 120k
Netflix 120k next month
```

Expected insight:

```text
Netflix subscription detected
```

---

# 5.4 Spending anomaly detection

Test dataset:

```text
Grab average 50k/week
Current week 150k
```

Expected:

```text
"Your Grab spending increased significantly."
```

---

# 5.5 Insight refresh

Test:

```text
Add new transaction
Open insights
```

Expected:

```text
Insights updated
```

---

# Milestone 5 success criteria

✔ weekly insights generated
✔ category summaries correct
✔ subscriptions detected
✔ anomaly detection works

---

# Final QA coverage overview

Total QA areas:

```text
Data persistence
Cloud sync
Manual transactions
Voice logging
OCR imports
Receipt scanning
Merchant normalization
Financial insights
```

Each milestone must pass QA before moving to the next.

---

