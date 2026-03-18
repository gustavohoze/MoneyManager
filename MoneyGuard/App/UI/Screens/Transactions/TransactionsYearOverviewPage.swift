import SwiftUI

struct TransactionsYearOverviewPage: View {
    let overview: TransactionYearOverviewPresentation
    let onShiftYear: (Int) -> Void
    let onSelectMonth: (Date) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                yearHeader

                LazyVGrid(columns: gridColumns, spacing: 10) {
                    ForEach(overview.months) { month in
                        Button(action: { onSelectMonth(month.monthStartDate) }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(month.shortMonthLabel)
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundStyle(palette.ink)

                                Text(month.totalSpentText)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(palette.secondaryInk)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                Text(month.transactionCountText)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(palette.secondaryInk)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)

                                Text(month.lastVisitedText)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(palette.secondaryInk)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                            .padding(10)
                            .background(
                                LinearGradient(
                                    colors: [palette.cardBackground, palette.cardBackground],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(month.isCurrentMonth ? palette.accent : palette.cardBorder, lineWidth: month.isCurrentMonth ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private var yearHeader: some View {
        HStack {
            Button(action: { onShiftYear(-1) }) {
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

            Text(String(overview.year))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(palette.ink)

            Spacer()

            Button(action: { onShiftYear(1) }) {
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
        .financeCard(palette: palette)
    }
}
