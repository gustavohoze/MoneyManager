import AppIntents

struct FinanceAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Log a transaction with \(.applicationName)",
                "I spent money with \(.applicationName)",
                "Spend money with \(.applicationName)"
            ],
            shortTitle: "Log Transaction",
            systemImageName: "plus.circle.fill"
        )
    }
}
