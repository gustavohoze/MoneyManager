import SwiftUI

struct AddTransactionMetadataCard: View {
    @Binding var selectedDate: Date
    @Binding var note: String
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(spacing: 12) {
            // Date field
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(palette.accent)

                    Text(String(localized: "Date"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Spacer()
                }

                DatePicker(String(localized: "Date"), selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.cardBorder, lineWidth: 1)
            )

            // Note field
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundStyle(palette.accent)

                    Text(String(localized: "Note"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Spacer()
                }

                TextField(String(localized: "Optional note"), text: $note, axis: .vertical)
                    .font(.system(.caption, design: .rounded))
                    .lineLimit(2...3)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(palette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.cardBorder, lineWidth: 1)
            )
        }
    }
}
