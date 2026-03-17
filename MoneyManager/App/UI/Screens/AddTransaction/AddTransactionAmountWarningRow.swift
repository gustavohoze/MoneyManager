import SwiftUI

struct AddTransactionAmountWarningRow: View {
    var suggested: Double?
    var onUseSuggested: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Amount seems unusually high", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.subheadline.weight(.medium))

            if let suggested {
                HStack {
                    Text("Did you mean Rp \(Int(suggested).formatted())?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Use this") {
                        onUseSuggested(String(format: "%.0f", suggested))
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
