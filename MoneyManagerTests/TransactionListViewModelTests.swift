import Foundation
import Testing
import CoreData
@testable import MoneyManager

private struct MockTransactionMutationService: TransactionMutating {
    var loadHandler: (UUID) throws -> TransactionEditDraft = { id in
        throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: id)
    }
    var updateHandler: (TransactionEditDraft) throws -> Void = { _ in }
    var deleteHandler: (UUID) throws -> Void

    func loadEditDraft(id: UUID) throws -> TransactionEditDraft {
        try loadHandler(id)
    }

    func updateTransaction(draft: TransactionEditDraft) throws {
        try updateHandler(draft)
    }

    func deleteTransaction(id: UUID) throws {
        try deleteHandler(id)
    }
}

private struct MockTransactionFormOptionsProvider: TransactionFormOptionsProviding {
    var options: TransactionFormOptions = TransactionFormOptions(accounts: [], categories: [])

    func loadOptions() throws -> TransactionFormOptions {
        options
    }
}

@MainActor
struct TransactionListViewModelTests {
    private func fixedNoonReferenceDate() -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: 2026,
            month: 3,
            day: 17,
            hour: 12,
            minute: 0,
            second: 0
        )

        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 1_742_208_000)
    }

    @Test("Test: sections are grouped by relative day")
    func load_withMixedDates_groupsTodayYesterdayEarlier() throws {
        // Objective: Validate required Today/Yesterday/Earlier grouping and newest-first ordering.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let paymentMethodID = try accountRepository.upsertPaymentMethod(name: "Cash", type: "cash", currency: "IDR")
        let foodID = try categoryRepository.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")

        let calendar = Calendar(identifier: .iso8601)
        let now = fixedNoonReferenceDate()
        let todayEarlier = calendar.date(byAdding: .hour, value: -2, to: now) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let earlier = calendar.date(byAdding: .day, value: -4, to: now) ?? now

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 40,
            currency: "IDR",
            date: todayEarlier,
            merchantRaw: "Coffee",
            merchantNormalized: "Coffee",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 20,
            currency: "IDR",
            date: now,
            merchantRaw: "Tea",
            merchantNormalized: "Tea",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 10,
            currency: "IDR",
            date: yesterday,
            merchantRaw: "Bus",
            merchantNormalized: "Bus",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 5,
            currency: "IDR",
            date: earlier,
            merchantRaw: "Old",
            merchantNormalized: "Old",
            categoryID: foodID,
            source: "manual",
            note: nil
        )

        let service = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let viewModel = TransactionListViewModel(
            dataProvider: service,
            optionsProvider: MockTransactionFormOptionsProvider()
        )

        viewModel.load(asOf: now)

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.sections.map(\.title) == ["Today", "Yesterday", "Earlier"])
        #expect(viewModel.sections[0].items.count == 2)
        #expect(viewModel.sections[1].items.count == 1)
        #expect(viewModel.sections[2].items.count == 1)

        // Newest first is required inside each section.
        #expect(viewModel.sections[0].items[0].merchant == "Tea")
        #expect(viewModel.sections[0].items[1].merchant == "Coffee")
    }

    @Test("Test: fallback names for missing mappings")
    func load_missingAccountAndCategory_usesFallbackLabels() throws {
        // Objective: Ensure list still renders when references are unresolved.
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)

        let now = fixedNoonReferenceDate()
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        _ = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 100,
            currency: "IDR",
            date: now,
            merchantRaw: " ",
            merchantNormalized: nil,
            categoryID: nil,
            source: "manual",
            note: nil
        )

        let service = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let viewModel = TransactionListViewModel(
            dataProvider: service,
            optionsProvider: MockTransactionFormOptionsProvider()
        )

        viewModel.load(asOf: now)

        let item = try #require(viewModel.sections.first?.items.first)
        #expect(item.category == "Uncategorized")
        #expect(item.account == "Cash")
        #expect(item.merchant == "Unknown")
    }

    @Test("Test: delete transaction updates list and action message")
    func deleteTransaction_success_removesItemAndSetsActionMessage() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)

        let now = fixedNoonReferenceDate()
        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let id = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 99,
            currency: "IDR",
            date: now,
            merchantRaw: "Delete Me",
            merchantNormalized: "Delete Me",
            categoryID: nil,
            source: "manual",
            note: nil
        )

        let service = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let mutation = MockTransactionMutationService(deleteHandler: { targetID in
            try transactionRepository.deleteTransaction(id: targetID)
        })
        let viewModel = TransactionListViewModel(
            dataProvider: service,
            mutationService: mutation,
            optionsProvider: MockTransactionFormOptionsProvider()
        )

        viewModel.load(asOf: now)
        viewModel.deleteTransaction(id: id, asOf: now)

        #expect(viewModel.sections.isEmpty)
        #expect(viewModel.actionMessage == "Transaction deleted.")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Test: delete transaction failure shows error")
    func deleteTransaction_failure_setsErrorMessage() {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)

        let service = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let mutation = MockTransactionMutationService(deleteHandler: { _ in
            throw CoreDataRepositoryError.missingReference(entity: "Transaction", id: UUID())
        })
        let viewModel = TransactionListViewModel(
            dataProvider: service,
            mutationService: mutation,
            optionsProvider: MockTransactionFormOptionsProvider()
        )

        viewModel.deleteTransaction(id: UUID())

        #expect(viewModel.actionMessage == nil)
        #expect(viewModel.errorMessage?.isEmpty == false)
    }

    @Test("Test: begin and save edit updates action")
    func editTransaction_success_updatesActionAndClearsSheetState() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let accountRepository = CoreDataPaymentMethodRepository(context: context)
        let categoryRepository = CoreDataCategoryRepository(context: context)
        let transactionRepository = CoreDataTransactionRepository(context: context)

        let paymentMethodID = try accountRepository.ensureDefaultPaymentMethod()
        let categoryID = try categoryRepository.upsertCategory(name: "Food", icon: "fork.knife", type: "expense")
        let referenceDate = fixedNoonReferenceDate()
        let transactionID = try transactionRepository.createTransaction(
            paymentMethodID: paymentMethodID,
            amount: 50,
            currency: "IDR",
            date: referenceDate,
            merchantRaw: "Before",
            merchantNormalized: "Before",
            categoryID: categoryID,
            source: "manual",
            note: nil
        )

        let service = TransactionListDataService(
            transactionRepository: transactionRepository,
            categoryRepository: categoryRepository,
            accountRepository: accountRepository
        )
        let options = MockTransactionFormOptionsProvider(
            options: TransactionFormOptions(
                accounts: [TransactionFormAccountOption(id: paymentMethodID, name: "Cash")],
                categories: [TransactionFormCategoryOption(id: categoryID, name: "Food")]
            )
        )
        let mutation = MockTransactionMutationService(
            loadHandler: { id in
                TransactionEditDraft(
                    id: id,
                    paymentMethodID: paymentMethodID,
                    amount: 50,
                    currency: "IDR",
                    date: referenceDate,
                    merchantRaw: "Before",
                    categoryID: categoryID,
                    note: nil
                )
            },
            updateHandler: { draft in
                try transactionRepository.updateTransaction(
                    id: draft.id,
                    paymentMethodID: draft.paymentMethodID,
                    amount: draft.amount,
                    currency: draft.currency,
                    date: draft.date,
                    merchantRaw: draft.merchantRaw,
                    merchantNormalized: draft.merchantRaw,
                    categoryID: draft.categoryID,
                    note: draft.note
                )
            },
            deleteHandler: { _ in }
        )

        let viewModel = TransactionListViewModel(
            dataProvider: service,
            mutationService: mutation,
            optionsProvider: options
        )

        viewModel.beginEdit(id: transactionID)
        let edit = try #require(viewModel.editState)

        var updated = edit.draft
        updated.merchantRaw = "After"
        viewModel.saveEdit(draft: updated, asOf: referenceDate)

        #expect(viewModel.editState == nil)
        #expect(viewModel.actionMessage == "Transaction updated.")
    }
}
