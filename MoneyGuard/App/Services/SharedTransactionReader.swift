import Foundation
import Combine

class SharedTransactionReader: ObservableObject {
    static let shared = SharedTransactionReader()
    
    @Published var pendingTransactions: [ParsedTransactionResult] = []
    
    private let userDefaults: UserDefaults?
    private let key = "PendingSharedTransactions"
    
    init() {
        self.userDefaults = UserDefaults(suiteName: "group.shecraa.MoneyManager")
        loadPending()
    }
    
    func loadPending() {
        guard let data = userDefaults?.data(forKey: key),
              let existing = try? JSONDecoder().decode([ParsedTransactionResult].self, from: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.pendingTransactions = existing
        }
    }
    
    func clearPending() {
        userDefaults?.removeObject(forKey: key)
        DispatchQueue.main.async {
            self.pendingTransactions = []
        }
    }
}
