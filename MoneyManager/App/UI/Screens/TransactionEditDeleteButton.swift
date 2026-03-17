import SwiftUI

struct TransactionEditDeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            HStack {
                Spacer()
                Text("Delete Transaction")
                Spacer()
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
