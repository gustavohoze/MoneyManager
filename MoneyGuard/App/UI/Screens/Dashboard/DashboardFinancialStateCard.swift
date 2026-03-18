import SwiftUI

struct DashboardFinancialStateCard: View {
    private enum InfoTopic: Identifiable {
        case financialState
        case projected
        case safeDaily

        var id: Int {
            switch self {
            case .financialState: return 0
            case .projected: return 1
            case .safeDaily: return 2
            }
        }

        var title: String {
            switch self {
            case .financialState:
                return String(localized: "Financial State")
            case .projected:
                return String(localized: "Projected")
            case .safeDaily:
                return String(localized: "Safe Daily")
            }
        }

        var message: String {
            switch self {
            case .financialState:
                return String(localized: "You might get negative value if you haven't logged any income, you can make this zero by going to Settings and set starting balance as the same amount of the minus.")
            case .projected:
                return String(localized: "Projected is an estimate of your balance after upcoming bills in this cycle.")
            case .safeDaily:
                return String(localized: "Safe Daily is the suggested amount you can spend per day until this cycle resets.")
            }
        }
    }

    @ObservedObject var viewModel: DashboardViewModel
    let palette: FinanceTheme.Palette
    let shouldMaskBalances: Bool
    let onRevealBalances: () -> Void
    @State private var activeInfoTopic: InfoTopic?

    private func maskedCurrencyText(_ value: Double) -> String {
        shouldMaskBalances ? "••••••" : viewModel.currencyText(value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(String(localized: "Financial State"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))

                Button {
                    activeInfoTopic = .financialState
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }

            Text(maskedCurrencyText(viewModel.currentBalance))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .onTapGesture {
                    if shouldMaskBalances {
                        onRevealBalances()
                    }
                }

            Text(String(localized: "Available balance"))
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.86))

            Divider()
                .overlay(.white.opacity(0.3))

            HStack(spacing: 12) {
                DashboardMetricPill(
                    title: String(localized: "Projected"),
                    value: maskedCurrencyText(viewModel.afterBillsBalance),
                    onInfoTap: { activeInfoTopic = .projected }
                )
                DashboardMetricPill(
                    title: String(localized: "Safe Daily"),
                    value: maskedCurrencyText(viewModel.safeDailySpend),
                    onInfoTap: { activeInfoTopic = .safeDaily }
                )
            }

            if shouldMaskBalances {
                Button {
                    onRevealBalances()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                        Text(String(localized: "Tap to reveal"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: [palette.heroStart, palette.heroEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: palette.accent.opacity(0.35), radius: 14, x: 0, y: 8)
        .alert(item: $activeInfoTopic) { topic in
            Alert(
                title: Text(topic.title),
                message: Text(topic.message),
                dismissButton: .default(Text(String(localized: "OK")))
            )
        }
    }
}
