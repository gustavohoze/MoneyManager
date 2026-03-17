import SwiftUI

struct MerchantAutocompleteView: View {
    @Binding var merchantText: String
    let suggestions: [MerchantSuggestion]
    let onSelectSuggestion: (MerchantSuggestion) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "storefront.fill")
                    .foregroundStyle(palette.accent)
                
                TextField(String(localized: "Merchant"), text: $merchantText)
                    .font(.system(.body, design: .rounded))
                
                if !merchantText.isEmpty {
                    Button(action: { merchantText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(palette.cardBackground)
            .cornerRadius(10)
            
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions) { suggestion in
                            MerchantSuggestionChip(
                                suggestion: suggestion,
                                onSelect: onSelectSuggestion
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}

struct MerchantSuggestionChip: View {
    let suggestion: MerchantSuggestion
    let onSelect: (MerchantSuggestion) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        Button(action: { onSelect(suggestion) }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.displayName)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                
                Text(String(localized: "×\(suggestion.usageCount)"))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(palette.secondaryInk)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(palette.accent.opacity(0.1))
            .cornerRadius(8)
            .foregroundStyle(palette.accent)
        }
    }
}

struct QuickMerchantsView: View {
    let frequentMerchants: [MerchantSuggestion]
    let onSelect: (MerchantSuggestion) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        if !frequentMerchants.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Frequent"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.secondaryInk)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 6) {
                    ForEach(frequentMerchants) { merchant in
                        Button(action: { onSelect(merchant) }) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(palette.accent)
                                    .font(.system(.caption))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(merchant.displayName)
                                        .font(.system(.callout, design: .rounded).weight(.semibold))
                                        .lineLimit(1)
                                    
                                    if let lastUsed = merchant.lastUsedDate {
                                        Text(MerchantSuggestionPresentationViewModel.relativeDateText(lastUsed))
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundStyle(palette.secondaryInk)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("×\(merchant.usageCount)")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(palette.secondaryInk)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(palette.cardBackground)
                            .cornerRadius(10)
                            .foregroundStyle(palette.ink)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    @State var merchant = ""
    let suggestions = [
        MerchantSuggestion(id: UUID(), displayName: "Warung Makan", usageCount: 5, lastUsedDate: Date()),
        MerchantSuggestion(id: UUID(), displayName: "Indomaret", usageCount: 3, lastUsedDate: Date().addingTimeInterval(-86400))
    ]
    
    return VStack(spacing: 16) {
        MerchantAutocompleteView(
            merchantText: $merchant,
            suggestions: suggestions,
            onSelectSuggestion: { _ in }
        )
        
        QuickMerchantsView(
            frequentMerchants: suggestions,
            onSelect: { _ in }
        )
        
        Spacer()
    }
    .padding()
}
