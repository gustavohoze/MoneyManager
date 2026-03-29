import SwiftUI

struct AddTransactionTypePickerCard: View {
    @Binding var selectedType: AddTransactionType
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: selectedType == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(palette.accent)

                Text(String(localized: "Type"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.ink)

                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(AddTransactionType.allCases, id: \.self) { type in
                    let activeColor: Color = (type == .expense) ? .red : palette.accent

                    Button {
                        selectedType = type
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text(type.title)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(selectedType == type ? .white : palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedType == type ? activeColor : palette.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedType == type ? activeColor : palette.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
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
