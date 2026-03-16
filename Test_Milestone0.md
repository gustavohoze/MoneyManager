I’m going to approach this like a **QA lead preparing a real test plan**, not a checklist. Your spec is decent, but it has blind spots: schema integrity, sync conflict handling, and repository correctness are where finance apps usually break. If you only test “happy paths,” you will ship a system that silently corrupts data.

So the test plan below focuses on **data correctness, sync integrity, and architecture boundaries**.

---

# Test Plan — Milestone 0

**Scope:** Data layer, persistence, sync, repositories, and export system
**Out of scope:** UI, OCR, voice, AI

Testing types used:

* **Unit tests**
* **Integration tests**
* **Persistence tests**
* **Sync tests**
* **Failure tests**

---

# 1. Project Structure Verification

### Goal

Ensure architectural separation exists and future features won’t bypass the data layer.

### What to test

#### 1.1 UI must not access Core Data directly

Search for imports.

Expectation:

```
UI
ViewModels
```

must **not import**

```
CoreData
NSPersistentContainer
NSManagedObjectContext
```

If they do → architecture violation.

---

#### 1.2 Only repository layer touches Core Data

Expected dependencies:

```
Repositories
   ↓
Persistence
```

NOT:

```
ViewModel → CoreData
UI → CoreData
Services → CoreData
```

---

#### 1.3 Services must be stateless

Services like:

```
MerchantResolver
AnalyticsService
```

must not hold database state.

They should receive dependencies via injection.

---

# 2. Core Data Schema Validation

This is where apps silently break later.

### Test: Entity existence

Verify Core Data model contains exactly:

```
Account
Transaction
Merchant
Category
```

Expectation:

```
4 entities only
```

---

### Test: Field validation

Verify each entity has correct attributes.

#### Account

Expected:

```
id UUID
name String
type String
currency String
createdAt Date
```

Test:

```
assert entity.attributeCount == 5
```

---

#### Transaction

Expected attributes:

```
id UUID
accountID UUID
amount Double
currency String
date Date
merchantRaw String
merchantNormalized String
categoryID UUID
source String
note String
createdAt Date
```

Key validation:

```
amount > 0
date != nil
accountID exists
```

---

#### Merchant

Check attributes:

```
rawName
normalizedName
brand
category
confidence
createdAt
```

Edge case tests:

```
confidence range = 0.0 – 1.0
```

Reject:

```
confidence > 1
confidence < 0
```

---

#### Category

Attributes:

```
id
name
icon
type
```

Validation:

```
name must be unique
```

---

# 3. Repository Layer Tests

Repositories are **the most important thing to test**.

If they fail, your entire system corrupts data.

---

# TransactionRepository Tests

### Test: createTransaction

Input:

```
amount = 50000
accountID = valid
categoryID = valid
```

Expected result:

```
transaction saved in Core Data
id auto generated
createdAt auto generated
```

---

### Test: invalid account

Input:

```
accountID = random UUID
```

Expected:

```
createTransaction throws error
```

---

### Test: negative amount

Input:

```
amount = -50000
```

Expected:

```
validation error
```

---

### Test: fetchTransactions(accountID)

Setup:

Create 3 transactions:

```
Account A → 2 transactions
Account B → 1 transaction
```

Expected:

```
fetchTransactions(A) returns 2
```

---

### Test: fetchTransactions(dateRange)

Input range:

```
2026-01-01 → 2026-01-31
```

Expected:

Only transactions inside range returned.

---

### Test: deleteTransaction

Steps:

```
create
delete
fetch
```

Expected:

```
transaction no longer exists
```

---

### Test: duplicate detection

Create:

```
merchant = Starbucks
amount = 45000
date = today
```

Insert same again.

Expected:

```
detectDuplicate = true
```

---

# AccountRepository Tests

### createAccount

Input:

```
name = BCA
type = bank
currency = IDR
```

Expected:

```
account created
```

---

### duplicate name test

Create two:

```
BCA
BCA
```

Expected:

Either:

```
reject duplicate
```

or

```
auto rename
```

But must **not silently allow duplicates without rule**.

---

# MerchantRepository Tests

### createMerchant

Input:

```
rawName = TRIJAYA PRATAMA TBK
normalizedName = Alfamart
confidence = 0.92
```

Expected:

Record saved correctly.

---

### raw name lookup

Query:

```
resolve(TRIJAYA PRATAMA TBK)
```

Expected:

Return normalized merchant.

---

# CategoryRepository Tests

### seed categories

First launch:

Expected categories:

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

Expected count:

```
8
```

---

### second launch

Expected:

```
NO duplicates
```

Still:

```
8 categories
```

---

# 4. Merchant Resolver Service

### Test: existing merchant

Input:

```
TRIJAYA PRATAMA TBK
```

Expected output:

```
Alfamart
confidence >= 0.8
```

---

### Test: unknown merchant

Input:

```
WARUNG BU SARI
```

Expected:

```
normalizedName = WARUNG BU SARI
confidence = low
```

---

### Test: fuzzy match

Input:

```
ALFA MART
```

Expected:

```
normalizedName = Alfamart
```

---

# 5. Analytics Tracker Tests

Analytics must **never capture sensitive data**.

Test event logging.

---

### Test: app_open

Expected payload:

```
event: app_open
timestamp
deviceID
```

Must NOT include:

```
transaction amount
merchant name
account name
```

---

### Test: transaction_created

Expected event:

```
transaction_created
```

Payload must NOT contain:

```
amount
merchant
account
note
```

Only metadata like:

```
timestamp
source
```

---

# 6. iCloud Availability Check

### Test: iCloud enabled

Mock:

```
iCloud account available
```

Expected:

```
no warning
sync enabled
```

---

### Test: iCloud disabled

Expected UI message:

```
iCloud is disabled. Your financial data may not sync across devices.
```

System behavior:

```
Core Data still works locally
```

---

# 7. CloudKit Sync Tests

Critical.

### Test: upload

Device A:

```
create transaction
```

Expected:

```
record appears in CloudKit
```

---

### Test: download

Device B:

Open app.

Expected:

```
transaction syncs locally
```

---

### Test: conflict

Device A:

```
edit transaction
```

Device B:

```
edit same transaction
```

Expected behavior defined:

Either:

```
last write wins
```

or

```
merge strategy
```

But must be deterministic.

---

# 8. Export System Tests

### CSV export

Expected format:

```
date,merchant,amount,category,account
2026-03-15,Starbucks,45000,Food,BCA
```

Test:

```
10 transactions → 10 rows
```

---

### JSON export

Expected structure:

```
[
 { transaction },
 { transaction }
]
```

Validation:

```
JSON parse succeeds
```

---

### Large dataset test

Insert:

```
10,000 transactions
```

Expected:

Export completes under:

```
3 seconds
```

---

# 9. Performance Tests

### Fetch performance

Insert:

```
50,000 transactions
```

Test:

```
fetchTransactions(dateRange)
```

Expected:

```
< 300 ms
```

---

# 10. Failure Tests (Most important)

### Database corruption

Simulate Core Data failure.

Expected:

```
app does not crash
error handled
```

---

### CloudKit unavailable

Expected:

```
local data still usable
sync resumes later
```

---

# Final Acceptance Criteria

Milestone passes when:

```
✔ repositories pass tests
✔ categories seeded once
✔ cloudkit sync works
✔ exports valid
✔ analytics safe
✔ merchant resolver works
✔ no architecture violations
```

---

## Brutal truth you should hear

Your spec ignores **three dangerous areas**:

1. **Core Data migration strategy**
   You will need it sooner than you think.

2. **CloudKit conflict resolution policy**
   If undefined, users will lose data.

3. **Currency handling**
   Using `Double` for money will bite you later.

A serious finance app normally uses:

```
Decimal / NSDecimalNumber
```

not `Double`.

You might want to fix that **now**, not in Milestone 3 when it's painful.

---
