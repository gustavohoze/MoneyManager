import Foundation

let filepath = "/Users/mac/Documents/Projects/Xcode/MoneyManager/MoneyGuard/App/UI/Navigation/MilestoneOneRootView.swift"
var content = try! String(contentsOfFile: filepath)

// Insert our SharedTransactionReader hook
let hookStartStr = ".onChange(of: scenePhase) { _, newPhase in"
let hookReplacement = """
.onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                SharedTransactionReader.shared.loadPending()
                if let first = SharedTransactionReader.shared.pendingTransactions.first {
                    addTransactionViewModel.amount = String(first.amount)
                    addTransactionViewModel.merchantName = first.merchantName
                    if let d = first.date {
                        addTransactionViewModel.date = d
                    }
                    if let n = first.note {
                        addTransactionViewModel.note = n
                    }
                    
                    showingAddTransactionSheet = true
                    SharedTransactionReader.shared.clearPending()
                }
            }
"""

content = content.replacingOccurrences(of: hookStartStr, with: hookReplacement)

try! content.write(toFile: filepath, atomically: true, encoding: .utf8)
