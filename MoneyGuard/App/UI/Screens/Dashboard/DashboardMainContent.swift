import SwiftUI

struct DashboardMainContent: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedWeeklyDayIndex: Int?
    @Binding var insightPage: Int
    var onSelectTransaction: (UUID) -> Void
    let palette: FinanceTheme.Palette
    @StateObject private var achievementService = AchievementService()
    @AppStorage("settings.hideBalances") private var hideBalances = false
    @AppStorage("dashboard.isBalanceHidden") private var isBalanceHidden = false
    @AppStorage("dashboard.dailyLoginStreak") private var dailyLoginStreak = 0
    @AppStorage("dashboard.lastLoginAt") private var lastLoginAt = 0.0
    @State private var toast: UniversalToastState?

    private var shouldMaskBalances: Bool {
        isBalanceHidden
    }

    private var streakTitle: String {
        dailyLoginStreak == 1
            ? String(localized: "1 day streak")
            : String(localized: "\(dailyLoginStreak) day streak")
    }

    private var earnedAchievements: [Achievement] {
        achievementService.getEarnedAchievements().filter { $0.isEarned }
    }

    private var selectedAchievement: Achievement? {
        achievementService.getSelectedAchievement()
    }

    private var isNewcomer: Bool {
        earnedAchievements.isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 30, height: 30)
                    .background(palette.accentSoft)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Daily Check-in"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.secondaryInk)

                    Text(streakTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.ink)
                }

                Spacer()

                // Show selected achievement or Newcomer badge
                if isNewcomer {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                        Text(String(localized: "Newcomer"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(palette.accent)
                } else if let achievement = selectedAchievement {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(.caption))
                        Text(achievement.title)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.80)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(palette.accent)
                    .frame(maxWidth: 120, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.cardBorder, lineWidth: 1)
            )

            DashboardFinancialStateCard(
                viewModel: viewModel,
                palette: palette,
                shouldMaskBalances: shouldMaskBalances,
                onRevealBalances: { isBalanceHidden = false },
                onToggleBalances: { isBalanceHidden.toggle() }
            )

            // Swipeable insight cards — one section at a time
            TabView(selection: $insightPage) {
                DashboardWeeklyTrendCard(
                    viewModel: viewModel,
                    selectedWeeklyDayIndex: $selectedWeeklyDayIndex,
                    insightPage: $insightPage,
                    shouldMaskBalances: shouldMaskBalances,
                    onRevealBalances: { isBalanceHidden = false },
                    palette: palette
                )
                    .padding(.horizontal, 4)
                    .tag(0)

                DashboardCategoryCard(
                    viewModel: viewModel,
                    insightPage: $insightPage,
                    shouldMaskBalances: shouldMaskBalances,
                    onRevealBalances: { isBalanceHidden = false },
                    palette: palette
                )
                    .padding(.horizontal, 4)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 216)
            .frame(maxWidth: .infinity)

            DashboardRecentTransactionsCard(
                viewModel: viewModel,
                palette: palette,
                shouldMaskBalances: shouldMaskBalances,
                onRevealBalances: { isBalanceHidden = false },
                onSelectTransaction: onSelectTransaction
            )
            .frame(maxWidth: .infinity)

        }
        .onChange(of: hideBalances) { _, isEnabled in
            if isEnabled {
                isBalanceHidden = true
            }
        }
        .onChange(of: achievementService.earnedAchievementIds) { _, _ in
            // Trigger view update when achievements change
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if hideBalances {
                    isBalanceHidden = true
                }
                updateDailyLoginStreakIfNeeded()
            }
        }
        .onAppear {
            updateDailyLoginStreakIfNeeded()
        }
        .overlay(alignment: .bottom) {
            if let toast {
                UniversalToastView(
                    state: toast,
                    palette: palette,
                    onUndo: nil,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            self.toast = nil
                        }
                    }
                )
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: toast?.id)
        .task(id: toast?.id) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = nil
            }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            guard let newValue, !newValue.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                toast = UniversalToastState(message: newValue, isError: true)
            }
        }
    }

    private func updateDailyLoginStreakIfNeeded(referenceDate: Date = Date()) {
        let calendar = Calendar.current

        guard lastLoginAt > 0 else {
            dailyLoginStreak = 1
            lastLoginAt = referenceDate.timeIntervalSince1970
            checkStreak7Achievement()
            checkStreak30Achievement()
            return
        }

        let lastDate = Date(timeIntervalSince1970: lastLoginAt)
        if calendar.isDate(lastDate, inSameDayAs: referenceDate) {
            return
        }

        if let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: lastDate)),
           calendar.isDate(nextDay, inSameDayAs: referenceDate) {
            dailyLoginStreak += 1
        } else {
            dailyLoginStreak = 1
        }

        lastLoginAt = referenceDate.timeIntervalSince1970
        checkStreak7Achievement()
        checkStreak30Achievement()
    }

    private func checkStreak7Achievement() {
        if dailyLoginStreak >= 7 && !achievementService.isAchievementEarned(id: "streak_7") {
            achievementService.unlockAchievement(id: "streak_7")
        }
    }

    private func checkStreak30Achievement() {
        if dailyLoginStreak >= 30 && !achievementService.isAchievementEarned(id: "streak_30") {
            achievementService.unlockAchievement(id: "streak_30")
        }
    }
}
