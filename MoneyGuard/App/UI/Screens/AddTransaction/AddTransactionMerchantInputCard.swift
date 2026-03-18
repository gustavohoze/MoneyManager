import SwiftUI

struct AddTransactionMerchantInputCard: View {
    @Binding var merchantText: String
    var suggestions: [MerchantSuggestion]
    var palette: FinanceTheme.Palette
    var onMerchantChange: (String) -> Void
    var onSelectSuggestion: (MerchantSuggestion) -> Void

    var body: some View {
        VStack(spacing: 12) {
            TextField(String(localized: "Store, restaurant, etc."), text: $merchantText)
                .font(.system(.body, design: .rounded))
                .onChange(of: merchantText) { _, newValue in
                    onMerchantChange(newValue)
                }

            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.id) { suggestion in
                            Button(action: { onSelectSuggestion(suggestion) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.secondaryInk)
                                    Text(suggestion.displayName)
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(palette.ink)
                                        .lineLimit(1)
                                    Image(systemName: "arrow.up.right.circle")
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.accent)
                                }
                                .padding(10)
                                .background(palette.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(palette.cardBorder, lineWidth: 1)
        )
    }
}
