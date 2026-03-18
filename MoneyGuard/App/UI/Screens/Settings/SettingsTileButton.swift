import SwiftUI

struct SettingsTileButton: View {
    let icon: String
    let label: String
    let description: String
    let palette: FinanceTheme.Palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(palette.accent)
                        .frame(width: 36, height: 36)
                        .background(palette.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.secondaryInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 100)
            .financeCard(palette: palette)
        }
    }
}
