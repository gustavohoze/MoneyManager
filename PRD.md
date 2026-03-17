Your product constraints:

* iOS-first indie app
* privacy-first (financial data stays on device/iCloud)
* extremely low infrastructure cost
* scalable later
* capture methods:

  * manual entry
  * voice logging
  * bank screenshot share
  * receipt scanning

Core Apple stack we will rely on:

* SwiftUI
* Core Data
* CloudKit
* Sign in with Apple

---

# Milestone 0 — Foundation & Data Architecture

Goal:
Create the **data layer, sync architecture, and project structure** so every future feature has a stable base.

Expected time: **5–7 days**

This milestone has **no OCR, no voice, no fancy UI**.

Just a stable system.

---

# 0.1 Project structure

You want strict separation between UI, data, and services.

Recommended structure:

```
App
├── UI
│   ├── Screens
│   ├── Components
│   └── Navigation
│
├── ViewModels
│
├── Persistence
│   ├── CoreDataStack
│   └── CloudKitConfig
│
├── Repositories
│   ├── TransactionRepository
│   ├── AccountRepository
│   ├── MerchantRepository
│   └── CategoryRepository
│
├── Services
│   ├── AnalyticsService
│   └── MerchantResolver
│
└── Extensions
```

This prevents your app from becoming a **massive ViewController mess**.

---

# 0.2 Persistence architecture

We will use:

* Core Data
* CloudKit

Implementation class:

```
NSPersistentCloudKitContainer
```

Data flow:

```
App UI
↓
ViewModel
↓
Repository
↓
Core Data
↓
CloudKit sync
↓
User iCloud storage
```

Important rule:

**Core Data is always the source of truth locally.**

CloudKit is only sync.

---

# 0.3 Core Data entities

We start with **four entities**.

These must be stable because changing schema later is painful.

---

## Entity: Account

Represents money containers.

Examples:

```
Cash
BCA Bank
ShopeePay
Credit Card
```

Fields:

```
id (UUID)
name (String)
type (String)
currency (String)
createdAt (Date)
```

Type values:

```
cash
bank
wallet
credit
```

---

## Entity: Transaction

The most important object in the system.

Fields:

```
id (UUID)
accountID (UUID)
amount (Double)
currency (String)
date (Date)

merchantRaw (String)
merchantNormalized (String)

categoryID (UUID)

source (String)
note (String)

createdAt (Date)
```

Source values:

```
manual
voice
bank_ocr
receipt_ocr
import
```

Never skip the `source` field — it becomes valuable for analytics later.

---

## Entity: Merchant

Used for normalization and categorization.

Fields:

```
id (UUID)

rawName (String)
normalizedName (String)

brand (String)
category (String)

confidence (Double)

createdAt (Date)
```

Example record:

```
rawName: TRIJAYA PRATAMA TBK
normalizedName: Alfamart
category: groceries
confidence: 0.92
```

---

## Entity: Category

Categories should **never be hardcoded in UI**.

Fields:

```
id (UUID)
name (String)
icon (String)
type (String)
```

Example categories:

```
Food
Transport
Groceries
Shopping
Bills
Entertainment
Income
```

---

# 0.4 Repository layer

UI must **never talk to Core Data directly**.

Repositories act as a data access layer.

Example:

```
TransactionRepository
```

Functions:

```
createTransaction()
updateTransaction()
deleteTransaction()
fetchTransactions()
detectDuplicate()
```

Example:

```
fetchTransactions(accountID)
fetchTransactions(dateRange)
```

---

# 0.5 Merchant resolver service

Create a service that handles merchant normalization.

```
MerchantResolver
```

Function:

```
resolve(rawMerchantName)
```

Example:

```
Input: TRIJAYA PRATAMA TBK
Output: Alfamart
```

Early implementation can be simple:

```
string similarity
keyword matching
existing merchant lookup
```

This service becomes critical when OCR arrives.

---

# 0.6 Analytics tracker

Analytics must be separate from financial data.

Only track **behavioral events**.

Events to implement now:

```
app_open
transaction_created
transaction_deleted
category_changed
merchant_corrected
```

Analytics data goes to your analytics backend (later we can define).

Do **not send transaction amounts or merchants**.

---

# 0.7 Initial category seeding

When the app launches first time, seed categories.

Example:

```
Food
Transport
Groceries
Shopping
Bills
Entertainment
Health
Income
```

Store them in Core Data.

---

# 0.8 iCloud availability check

On app launch:

Check if iCloud is available.

If not:

Show warning:

```
iCloud is disabled. Your financial data may not sync across devices.
```

Users must understand backup risks.

---

# 0.9 Data export system

Finance apps must support export.

Implement export to:

```
CSV
JSON
```

Example CSV:

```
date,merchant,amount,category,account
2026-03-15,Starbucks,45000,Food,BCA
```

Users feel safer when they can leave.

---

# Milestone 0 success criteria

You know milestone 0 is complete when:

✔ Core Data schema works
✔ CloudKit sync works
✔ categories seeded
✔ repositories working
✔ analytics tracker implemented
✔ export feature works

No UI polish required.

---

# What we deliberately DO NOT build yet

Not yet:

```
manual transaction UI
voice logging
OCR
receipt scanning
AI insights
```

Those start in the next milestone.

---

# Milestone 1 — Core Expense Tracker

Goal:
Users can **log, view, and manage transactions** manually.

Expected development time: **2–3 weeks**

This milestone builds the **minimum viable product**.

Frameworks used:

* SwiftUI
* Core Data
* CloudKit

No OCR or voice yet.

---

# 1.1 Core user flow

Your app must support the following loop:

```text
Open app
↓
See spending summary
↓
Add transaction
↓
Review transaction list
↓
Repeat
```

If this loop feels slow or confusing, the product will fail later.

---

# 1.2 Required screens

You only build **four screens**.

Do not add more yet.

```text
Dashboard
Transaction List
Add Transaction
Settings
```

---

# 1.3 Dashboard screen

Purpose: show quick financial overview.

Displayed information:

```text
Current balance
Weekly spending
Top spending category
Recent transactions
```

Example layout:

```text
Balance: Rp 3,200,000

This week spending:
Rp 540,000

Top category:
Food
```

Recent transactions preview:

```text
Grab           9,000
Starbucks      45,000
Alfamart       28,000
```

Balance calculation:

```text
balance = sum(income) - sum(expense)
```

Never store balance directly.

---

# 1.4 Transaction list screen

Purpose: show full financial history.

Display fields:

```text
Merchant
Amount
Category
Date
Account
```

Sorting:

```text
Newest first
```

Grouping:

```text
Today
Yesterday
Earlier
```

Optional (nice but not required):

```text
Monthly grouping
```

---

# 1.5 Add transaction screen

This screen is **extremely important** because it will be used often.

Required fields:

```text
Amount
Merchant
Category
Account
Date
```

Optional fields:

```text
Note
Location
```

UI suggestions:

Amount input should be **large numeric keypad**.

Merchant field should support **autocomplete**.

---

# 1.6 Merchant memory

This feature drastically improves UX.

When a user categorizes a merchant once:

```text
Grab → Transport
Starbucks → Food
```

Store mapping.

Next time auto-fill category.

Implementation:

```text
MerchantResolver
↓
Lookup normalized merchant
↓
Apply saved category
```

---

# 1.7 Transaction editing

Users must be able to:

```text
Edit transaction
Delete transaction
Change category
Change account
```

Editing should update Core Data and sync to CloudKit.

---

# 1.8 Duplicate transaction detection

Even before OCR arrives, duplicates can happen.

Detect duplicates using:

```text
Same amount
Similar merchant
Same date
```

If detected:

Show warning:

```text
"This looks similar to an existing transaction"
```

Do not block saving.

---

# 1.9 Default accounts

Seed default accounts when the app launches first time.

Example:

```text
Cash
Bank
Credit Card
Wallet
```

Users can rename or delete.

---

# 1.10 Analytics events

Track user behavior from this milestone.

Events:

```text
transaction_created
transaction_deleted
transaction_edited
category_changed
account_created
```

Important metric:

```text
transactions_per_user_per_week
```

If this is low, the app is not sticky.

---

# 1.11 Error handling

Edge cases:

### Invalid amount

Reject:

```text
0
negative numbers
empty value
```

---

### Missing merchant

Allow saving but set:

```text
merchantRaw = "Unknown"
```

---

### Category missing

Default to:

```text
Uncategorized
```

---

# 1.12 Data export

Export should now include **all transactions**.

Formats:

```text
CSV
JSON
```

Example CSV row:

```text
2026-03-15,Starbucks,45000,Food,BCA
```

---

# Milestone 1 success criteria

Milestone 1 is complete when:

✔ User can create accounts
✔ User can manually log transactions
✔ Transaction list updates instantly
✔ Dashboard shows spending summary
✔ Data syncs with CloudKit
✔ Export works

At this stage the app is already a **simple finance tracker**.

---

# What we intentionally still DO NOT build

Not yet:

```text
voice logging
OCR
receipt scanning
AI insights
merchant ML
```

Those arrive in later milestones.

---

# Product validation after Milestone 1

You should test with **real users**.

Ask them to use the app for **1 week**.

Watch for these signals:

Good signal:

```text
Users log expenses daily
```

Bad signal:

```text
Users forget to log expenses
```

If users don’t log manually, automation features will be required sooner.

---

# Milestone 2 — Fast Capture System

Goal:
Allow users to log transactions **in under 2 seconds**.

Estimated development time: **1.5–2 weeks**

Main framework:

* App Intents

Supporting frameworks:

* SwiftUI
* Core Data

---

# 2.1 Fast capture philosophy

Your product must support **multiple quick entry paths**.

Different users prefer different input methods.

Your app will support:

```text
Quick Add Button
Voice Logging
Siri Commands
Shortcuts Automation
Lock Screen Logging
```

All of them must create the same `Transaction` object.

---

# 2.2 Quick Add transaction

Add a **floating action button** on main screens.

Example UI:

```text
+
```

Pressing it opens **Quick Add Sheet**.

Fields:

```text
Amount
Merchant
Category (auto)
Account
```

Important rules:

Amount field appears **first and focused**.

Keyboard = **numeric keypad**.

Goal:

```text
Enter amount
Enter merchant
Tap save
```

Total interaction time:

```text
~2 seconds
```

---

# 2.3 Merchant auto-complete

When user types merchant name:

```text
Star...
```

Show suggestions:

```text
Starbucks
Star Market
Star Coffee
```

Data source:

```text
Merchant table
Recent transactions
```

Benefits:

```text
Faster input
Better normalization
Better categorization
```

---

# 2.4 Voice logging

Voice logging allows users to say transactions naturally.

Example commands:

```text
"Log 50k coffee"
"Add 120k groceries"
"Record 30k Grab ride"
```

Intent name:

```text
AddTransactionIntent
```

Parameters:

```text
amount
merchant
category
account
date
```

Example command parsing:

Input:

```text
"Log 40k Starbucks"
```

Parsed:

```text
amount: 40000
merchant: Starbucks
category: Food
```

Category predicted from merchant history.

---

# 2.5 Siri integration

Voice commands should work through Siri.

Example:

```text
"Hey Siri, log 50k coffee"
```

Siri triggers `AddTransactionIntent`.

Flow:

```text
Siri command
↓
App Intent
↓
TransactionRepository
↓
Core Data
↓
CloudKit sync
```

User receives confirmation:

```text
"Added 50,000 for Starbucks."
```

---

# 2.6 Apple Shortcuts integration

Users can automate logging.

Example shortcuts:

```text
"Log daily lunch"
"Record taxi expense"
```

Shortcut parameters:

```text
Amount
Merchant
Category
Account
```

Advanced users can automate expenses.

---

# 2.7 Lock screen quick logging

Users should log transactions **without opening the app fully**.

Methods:

```text
Lock screen widget
Action button
Control Center shortcut
```

User interaction:

```text
Tap widget
↓
Quick Add sheet
↓
Save transaction
```

Target logging time:

```text
< 3 seconds
```

---

# 2.8 Smart category prediction

When merchant is known:

Example:

```text
Starbucks
```

Category predicted automatically:

```text
Food
```

Implementation:

Use merchant mapping table.

```text
merchantNormalized → category
```

User can override.

Override updates merchant mapping.

---

# 2.9 Recent merchant suggestions

Quick Add screen should show:

```text
Recent merchants
```

Example:

```text
Grab
Starbucks
Alfamart
```

User taps instead of typing.

This reduces friction significantly.

---

# 2.10 Voice parsing rules

Voice commands may be ambiguous.

Example:

```text
"Log 50 dinner"
```

System resolves:

```text
merchant: dinner
category: Food
amount: 50
```

If missing information:

Example:

```text
"Log coffee"
```

System asks:

```text
"What amount?"
```

Keep voice interactions simple.

---

# 2.11 Analytics events

Track usage of capture methods.

Events:

```text
quick_add_used
voice_logging_used
shortcut_logging_used
lockscreen_logging_used
```

Important metric:

```text
fast_capture_usage_rate
```

If this is low, logging is still too slow. 

---

# 2.12 Error handling

Edge cases:

### Voice amount unclear

Example:

```text
"log coffee"
```

Prompt user:

```text
"How much was the transaction?"
```

---

### Merchant unknown

Allow save with:

```text
merchantRaw
```

Normalization can happen later.

---

# Milestone 2 success criteria

Milestone 2 is complete when:

✔ User can log transactions via Quick Add
✔ Siri voice commands work
✔ Lock screen logging works
✔ Merchant auto-complete works
✔ Category prediction works

Now logging should feel **almost effortless**.

---

# What we still intentionally DO NOT build

Not yet:

```text
bank screenshot OCR
receipt scanning
merchant AI model
financial insights
```

Those arrive next.

---

Good. Now we move to **Milestone 3**. This is the most technically complex milestone so far because it introduces **OCR + image workflows + share extensions**. If this milestone is poorly designed, the OCR feature will feel unreliable and users will abandon it.

The goal here is **transaction capture without typing**.

---

# Milestone 3 — OCR Import System

Goal:
Allow users to create transactions by:

* sharing **bank screenshots**
* scanning **paper receipts**

Estimated development time: **3–4 weeks**

Primary frameworks:

* Apple Vision Framework
* VisionKit
* Share Extensions
* App Groups

---

# 3.1 Capture paths

This milestone adds **two new input methods**.

```text id="jhb39d"
Bank screenshot share
Receipt scanning
```

After this milestone your app supports:

```text id="pjb8iv"
Manual entry
Voice logging
Bank screenshot OCR
Receipt OCR
```

All four methods produce the same **Transaction entity**.

---

# 3.2 OCR architecture

Your system must detect **document type** before parsing.

Pipeline:

```text id="0jip07"
Image
↓
Vision OCR
↓
Text blocks
↓
Document classifier
↓
Bank screenshot OR receipt
↓
Different parsing logic
```

This separation is crucial.

Bank UIs are structured.
Receipts are messy.

---

# 3.3 Bank screenshot import (Share Extension)

Users should capture bank transactions like this:

```text id="18gl9m"
Bank app
↓
Screenshot
↓
Share
↓
Select your app
↓
Transaction parsed
```

This requires an **iOS share extension**.

---

## Share extension responsibilities

The extension should:

```text id="7r49g1"
Receive image
Run OCR
Parse transaction
Send result to main app
```

Important constraint:

```text id="dly1q4"
Share extension runtime < 2 seconds
```

Apple may terminate slow extensions.

---

## Extension architecture

```text id="2pjkh6"
Share Extension
 ├ Receive screenshot
 ├ Run Vision OCR
 ├ Extract transaction candidate
 └ Save to shared container
```

Data transfer between extension and app uses:

```text id="ed8o4k"
App Group container
```

---

# 3.4 Bank screenshot parsing

Typical bank screenshot text:

```text id="sh7sjm"
15/03
GRAB *TRIP
9,000 DB
```

Parser extracts:

```text id="yh8bj3"
date
merchant
amount
transaction type
```

Example result:

```text id="vyn94l"
merchant: Grab
amount: 9000
date: 2026-03-15
type: debit
```

---

# 3.5 OCR preprocessing

Before OCR runs, apply preprocessing.

Steps:

```text id="rddr05"
resize image
grayscale conversion
contrast boost
noise reduction
```

Benefits:

```text id="gnjflh"
+15–20% OCR accuracy
```

---

# 3.6 Receipt scanning

Receipts are captured with camera.

Framework used:

* VisionKit

VisionKit provides:

```text id="26a2hb"
automatic edge detection
document cropping
perspective correction
```

This improves OCR dramatically.

---

# Receipt scan flow

User interaction:

```text id="p2vwyq"
Open app
↓
Tap "Scan Receipt"
↓
Camera scanner
↓
Auto crop
↓
OCR extraction
↓
Transaction preview
↓
Save
```

---

# 3.7 Receipt parsing logic

Receipt text example:

```text id="31w9ds"
STARBUCKS
Latte        45,000
Croissant    30,000
TOTAL        82,500
```

You only need:

```text id="pum34r"
merchant
total amount
date
```

Extraction strategy:

1. merchant = first text block
2. total = line containing **TOTAL**
3. date = detected date pattern

Ignore line items initially.

---

# 3.8 Transaction preview screen

OCR results must always be **reviewed by user**.

Preview fields:

```text id="vbfyxj"
Merchant
Amount
Date
Account
Category
```

Buttons:

```text id="sy08bd"
Save
Edit
Cancel
```

Never auto-save OCR transactions.

---

# 3.9 Duplicate detection

OCR imports can duplicate existing entries.

Check for duplicates using:

```text id="zow5az"
same amount
similar merchant
same date
```

If duplicate likely:

```text id="kzyntn"
Show warning
```

Example:

```text id="21odc4"
"This transaction looks similar to an existing entry."
```

---

# 3.10 Screenshot detection (optional improvement)

The app can detect new screenshots automatically.

Framework:

* PhotoKit

Example flow:

```text id="1t19mo"
User takes screenshot
↓
App detects screenshot
↓
Suggest import
```

This increases OCR usage.

---

# 3.11 Analytics events

Track OCR performance carefully.

Events:

```text id="dqu04u"
bank_ocr_started
bank_ocr_success
bank_ocr_failed

receipt_scan_started
receipt_scan_success
receipt_scan_failed
```

Critical metric:

```text id="8rfbvr"
OCR success rate
```

Target:

```text id="01z0s8"
>80%
```

Below that users stop trusting OCR.

---

# 3.12 Error handling

OCR may fail due to:

```text id="fa82h4"
blurry images
dark screenshots
faded receipts
weird fonts
```

Fallback behavior:

```text id="skh0iz"
Show OCR text
Allow manual editing
```

Never discard the scan.

---

# Milestone 3 success criteria

Milestone 3 is complete when:

✔ Bank screenshots can be shared into the app
✔ OCR extracts merchant, amount, and date
✔ Receipt scanning works via camera
✔ Transaction preview allows editing
✔ Duplicate detection works

After this milestone your app supports **fully automated expense capture**.

---

# What we still intentionally do NOT build

Not yet:

```text id="pfjdn2"
merchant AI classification
financial insights
spending analysis
anomaly detection
```

Those belong to the next milestone.

---

# Milestone 4 — Merchant Intelligence System

Goal:
Automatically understand merchants and categorize transactions with minimal user correction.

Estimated development time: **2–3 weeks**

Primary framework for on-device ML:

* Core ML

Supporting tools:

* Natural Language Framework

---

# 4.1 Why this system is necessary

Transaction data is messy.

Example merchant names from different sources:

```text id="6wtr5o"
STARBUCKS JKT
STARBUCKS COFFEE
STARBUCKS RESERVE
```

Users expect:

```text id="kofsgv"
Starbucks
```

Without normalization:

```text id="y9eibf"
analytics becomes inaccurate
category prediction fails
duplicate merchants appear
```

This milestone solves that.

---

# 4.2 Merchant intelligence pipeline

Processing pipeline:

```text id="p1ggk0"
Raw merchant name
↓
Text normalization
↓
Merchant matching
↓
Brand normalization
↓
Category prediction
```

Example:

```text id="7b3k7x"
STARBUCKS RESERVE
↓
Starbucks
↓
Food
```

---

# 4.3 Merchant normalization

First step: normalize merchant text.

Rules:

```text id="i0nfoc"
remove numbers
remove location codes
remove special characters
convert to lowercase
trim whitespace
```

Example:

```text id="pr6c0q"
STARBUCKS JKT 234
```

Normalized:

```text id="pyyax2"
starbucks
```

---

# 4.4 Merchant dictionary

Maintain a dictionary table inside the app.

Example records:

```text id="l2x1di"
starbucks → Starbucks
grab → Grab
trijaya → Alfamart
```

Stored in:

```text id="ya8wbc"
Merchant table
```

Structure:

```text id="phap92"
normalizedName
brand
category
confidence
```

When new merchants appear, they are added to the table.

---

# 4.5 Similarity matching

If merchant is unknown, run similarity search.

Example input:

```text id="b0rx0m"
STARBUCKS INDONESIA
```

Similarity algorithm finds:

```text id="jaivsk"
Starbucks
```

Implementation options:

```text id="l8t8qe"
Levenshtein distance
cosine similarity
token matching
```

This step prevents duplicate merchants.

---

# 4.6 Category prediction

Once merchant is identified, category is predicted.

Example:

```text id="sfw65r"
Starbucks → Food
Grab → Transport
Alfamart → Groceries
```

Prediction sources:

```text id="n5zhn1"
merchant history
merchant dictionary
ML classifier
```

Priority order:

```text id="pn03mw"
user history
merchant dictionary
ML model
```

User history should override everything.

---

# 4.7 On-device ML classifier

For unknown merchants, run classification.

Model input:

```text id="l9p8vx"
merchant name text
```

Model output:

```text id="6k5vva"
category
confidence
```

Example:

```text id="4r6x7o"
merchant: netflix
category: Entertainment
confidence: 0.94
```

This model is small and runs fully on-device using:

* Core ML

---

# 4.8 Learning from user corrections

The system must improve automatically.

If user changes:

```text id="k7d8pl"
Grab → Transport
```

Save mapping.

Next time:

```text id="t4ag3p"
Grab auto-categorized
```

This feedback loop improves accuracy quickly.

---

# 4.9 Merchant database growth

Over time your merchant table grows.

Example dataset:

```text id="i5ur3f"
Grab
Starbucks
Netflix
Spotify
Alfamart
Indomaret
Gojek
Tokopedia
Shopee
```

With enough entries, most merchants are auto-recognized.

---

# 4.10 Merchant UI improvements

Merchant normalization improves several parts of UI.

Transaction list:

```text id="x33y23"
Starbucks
```

instead of:

```text id="bdz6y0"
STARBUCKS RESERVE JKT
```

Cleaner interface.

---

# 4.11 Merchant logos (optional upgrade)

You can optionally attach logos.

Example:

```text id="b24sh1"
Starbucks logo
Grab logo
Netflix logo
```

This improves recognition.

Logos stored locally.

---

# 4.12 Analytics events

Track merchant intelligence performance.

Events:

```text id="fr2t8p"
merchant_auto_normalized
merchant_user_corrected
category_auto_assigned
category_user_corrected
```

Important metric:

```text id="u6w3bm"
auto_categorization_accuracy
```

Target:

```text id="k7h9h1"
>85%
```

---

# 4.13 Error handling

If system is unsure:

```text id="zv7vkp"
confidence < 0.6
```

Do not auto-categorize.

Instead show:

```text id="n57go0"
suggested categories
```

Let user choose.

---

# Milestone 4 success criteria

Milestone 4 is complete when:

✔ merchants are normalized automatically
✔ categories are predicted automatically
✔ duplicate merchants are avoided
✔ user corrections improve predictions

At this stage the app feels **intelligent**.

---

# What we still have not built

Still missing:

```text id="ug8l79"
spending insights
financial trends
anomaly detection
budget coaching
```

These features give users **reasons to open the app regularly**.

---

Good. Now we reach the **final planned milestone**. Everything before this milestone focused on **capturing transactions correctly**. This one focuses on **helping users understand their money**.

If your app only records data, users will stop opening it.
Insights give them a **reason to come back**.

---

# Milestone 5 — Financial Insights & Intelligence

Goal:
Turn transaction data into **clear financial insights**.

Estimated development time: **2–3 weeks**

Most logic in this milestone is **data analysis**, not heavy ML.

Frameworks used:

* Core Data
* SwiftUI

Optional future ML:

* Core ML

---

# 5.1 Insights architecture

Create a dedicated service:

```text id="kkq02h"
InsightsEngine
```

Responsibilities:

```text id="jjnl2l"
analyze spending
detect patterns
generate insights
```

Processing schedule:

```text id="j0iv5c"
daily analysis
weekly analysis
monthly analysis
```

These jobs can run **on-device**.

---

# 5.2 Weekly spending summary

Provide a weekly spending overview.

Example insight:

```text id="f1v9hu"
You spent Rp1,250,000 this week.
```

Comparison insight:

```text id="0ljh3t"
Spending increased 18% compared to last week.
```

Calculation:

```text id="5d1f7d"
sum(all transactions within week)
```

---

# 5.3 Category spending analysis

Show top spending categories.

Example:

```text id="7pdc23"
Food: Rp 520,000
Transport: Rp 180,000
Groceries: Rp 140,000
```

This helps users quickly identify **spending habits**.

---

# 5.4 Spending trends

Detect trends over time.

Example:

```text id="h1qk3o"
Food spending increased 35% this month.
```

Trend detection:

```text id="72ehpt"
current period
vs
previous period
```

This encourages behavior awareness.

---

# 5.5 Merchant spending insights

Detect frequent merchants.

Example:

```text id="yjdc2o"
You spent Rp320,000 at Starbucks this month.
```

Calculation:

```text id="bdqnj0"
sum transactions grouped by merchant
```

---

# 5.6 Subscription detection

Detect recurring payments.

Example pattern:

```text id="rbj9v3"
Netflix
Spotify
iCloud
```

Detection rule:

```text id="7k70ce"
same merchant
similar amount
monthly interval
```

Example insight:

```text id="rrf4x2"
Netflix subscription detected: Rp 120,000 / month
```

Users often forget subscriptions.

---

# 5.7 Spending anomaly detection

Detect unusual spending.

Example:

```text id="rt2g9a"
Your Grab spending increased 70% this week.
```

Detection rule:

```text id="k4vkmn"
current spending
>
average spending * threshold
```

Threshold example:

```text id="dkyuym"
1.5x
```

---

# 5.8 Budget alerts (optional)

Allow users to set monthly budgets.

Example:

```text id="r93b1q"
Food budget: Rp 1,500,000
```

Alert:

```text id="y04u5g"
You have used 80% of your food budget.
```

This feature increases retention.

---

# 5.9 Insight presentation

Create a dedicated screen:

```text id="59bta6"
Insights
```

Sections:

```text id="o1fbqu"
Weekly summary
Category breakdown
Merchant insights
Spending alerts
```

This screen should feel like **financial health feedback**.

---

# 5.10 Insight generation timing

Insights should update:

```text id="xwwd3x"
on app launch
daily background refresh
```

Background tasks should run efficiently.

---

# 5.11 Analytics events

Track engagement with insights.

Events:

```text id="bq2hmp"
insight_viewed
insight_dismissed
budget_created
budget_exceeded
```

Important metric:

```text id="h5xq12"
insight_engagement_rate
```

If low, insights are not useful.

---

# 5.12 Privacy design

All financial analysis should remain **on-device**.

Do not send transaction data to servers.

Benefits:

```text id="kmc7zn"
strong privacy
lower infrastructure cost
better user trust
```

---

# Milestone 5 success criteria

Milestone 5 is complete when:

✔ weekly spending insights appear
✔ category spending summary works
✔ recurring subscriptions detected
✔ spending anomalies detected
✔ insights screen displays results

Now the app functions as a **financial intelligence tool**, not just a recorder.

---

# Final product capabilities after all milestones

Your app now supports:

```text id="gdyshs"
Manual transaction entry
Voice logging
Bank screenshot OCR
Receipt scanning
Merchant intelligence
Financial insights
```

And everything runs mostly **on-device**, keeping infrastructure costs minimal.

---

# Final architecture overview

```text id="o15ovb"
iOS App
 ├ SwiftUI UI
 ├ Core Data
 ├ CloudKit Sync
 ├ Vision OCR
 ├ VisionKit Scanner
 ├ App Intents
 ├ CoreML merchant model
 └ Insights Engine
```

Server infrastructure only needed for **analytics**.

---

# Realistic total development timeline

| Milestone             | Time      |
| --------------------- | --------- |
| Foundation            | 1 week    |
| Core tracker          | 3 weeks   |
| Fast capture          | 2 weeks   |
| OCR system            | 3–4 weeks |
| Merchant intelligence | 2–3 weeks |
| Insights              | 2–3 weeks |

Total:

```text
~13–16 weeks solo development
```

---
