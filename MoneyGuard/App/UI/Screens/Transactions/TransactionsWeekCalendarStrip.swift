import SwiftUI

struct TransactionsWeekCalendarStrip: View {
    let title: String
    let days: [TransactionCalendarDayPresentation]
    let onSelectDate: (Date) -> Void
    let onShiftWeek: (Int) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: { onShiftWeek(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.ink)
                        .frame(width: 34, height: 34)
                        .background(palette.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(palette.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.secondaryInk)

                Spacer()

                Button(action: { onShiftWeek(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.ink)
                        .frame(width: 34, height: 34)
                        .background(palette.cardBackground)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(palette.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                ForEach(days) { day in
                    Button(action: { onSelectDate(day.date) }) {
                        VStack(spacing: 5) {
                            Text(day.weekdayLabel)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(day.isSelected ? Color.white.opacity(0.84) : palette.secondaryInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Text(day.dayNumberText)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(day.isSelected ? Color.white : palette.ink)

                            Text(day.transactionCountText)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(day.isSelected ? Color.white.opacity(0.9) : palette.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            day.isSelected
                                ? LinearGradient(
                                    colors: [palette.heroStart, palette.heroEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [palette.cardBackground, palette.cardBackground],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(day.isSelected ? Color.clear : palette.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .financeCard(palette: palette)
    }
}
