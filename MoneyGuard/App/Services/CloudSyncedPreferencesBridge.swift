import Foundation

final class CloudSyncedPreferencesBridge {
    static let shared = CloudSyncedPreferencesBridge()

    static let syncedKeys: [String] = [
        "settings.defaultMonthlyBudget",
        "settings.budgetWarningThreshold",
        "settings.budgetCriticalThreshold",
        "settings.openingBalance",
        "settings.displayCurrencyCode",
        "settings.notifyDailyReminder",
        "settings.notifyMonthlyReview",
        "settings.lockWithFaceID",
        "settings.hideBalances",
        "dashboard.isBalanceHidden",
        "settings.lastUsedAccountID",
        "category_budgets_v1"
    ]

    private let defaults: UserDefaults
    private let cloudStoreProvider: () -> NSUbiquitousKeyValueStore
    private let notificationCenter: NotificationCenter
    private var cloudStore: NSUbiquitousKeyValueStore?

    private var isStarted = false
    private var isApplyingCloudChanges = false

    init(
        defaults: UserDefaults = .standard,
        cloudStoreProvider: @escaping () -> NSUbiquitousKeyValueStore = { .default },
        notificationCenter: NotificationCenter = .default
    ) {
        self.defaults = defaults
        self.cloudStoreProvider = cloudStoreProvider
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard !isStarted else {
            return
        }

        guard FileManager.default.ubiquityIdentityToken != nil else {
            return
        }

        let cloudStore = cloudStoreProvider()
        self.cloudStore = cloudStore

        isStarted = true

        notificationCenter.addObserver(
            self,
            selector: #selector(handleDefaultsChange),
            name: UserDefaults.didChangeNotification,
            object: defaults
        )

        notificationCenter.addObserver(
            self,
            selector: #selector(handleCloudStoreChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )

        // Pull first so this device adopts cloud values when available.
        cloudStore.synchronize()
        applyCloudValues(for: Self.syncedKeys)
        pushDefaultsToCloud(for: Self.syncedKeys)
        cloudStore.synchronize()
    }

    @objc
    private func handleDefaultsChange() {
        guard let cloudStore else {
            return
        }
        guard !isApplyingCloudChanges else {
            return
        }
        pushDefaultsToCloud(for: Self.syncedKeys)
        cloudStore.synchronize()
    }

    @objc
    private func handleCloudStoreChange(_ notification: Notification) {
        guard cloudStore != nil else {
            return
        }
        let keys = (notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]) ?? Self.syncedKeys
        applyCloudValues(for: keys)
    }

    private func pushDefaultsToCloud(for keys: [String]) {
        guard let cloudStore else {
            return
        }
        for key in keys {
            guard let value = defaults.object(forKey: key) else {
                continue
            }

            switch value {
            case let stringValue as String:
                cloudStore.set(stringValue, forKey: key)
            case let numberValue as NSNumber:
                cloudStore.set(numberValue, forKey: key)
            case let dataValue as Data:
                cloudStore.set(dataValue, forKey: key)
            case let dateValue as Date:
                cloudStore.set(dateValue, forKey: key)
            default:
                continue
            }
        }
    }

    private func applyCloudValues(for keys: [String]) {
        guard let cloudStore else {
            return
        }
        isApplyingCloudChanges = true
        defer { isApplyingCloudChanges = false }

        for key in keys where Self.syncedKeys.contains(key) {
            guard let value = cloudStore.object(forKey: key) else {
                continue
            }

            switch value {
            case let stringValue as String:
                defaults.set(stringValue, forKey: key)
            case let numberValue as NSNumber:
                defaults.set(numberValue, forKey: key)
            case let dataValue as Data:
                defaults.set(dataValue, forKey: key)
            case let dateValue as Date:
                defaults.set(dateValue, forKey: key)
            default:
                continue
            }
        }
    }

}
