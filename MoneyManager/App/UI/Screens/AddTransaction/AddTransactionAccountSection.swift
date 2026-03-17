import SwiftUI

struct AddTransactionAccountSection: View {
    let accounts: [TransactionFormAccountOption]
    let selectedAccountID: UUID?
    let selectedAccountName: String
    let onSelect: (UUID) -> Void

    var body: some View {
        Section {
            Menu {
                ForEach(accounts) { account in
                    Button {
                        onSelect(account.id)
                    } label: {
                        HStack {
                            Text(account.name)
                            if selectedAccountID == account.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedAccountName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Payment Method")
        }
    }
}
