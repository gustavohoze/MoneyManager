import SwiftUI

struct DashboardAchievementsCard: View {
    let palette: FinanceTheme.Palette
    let achievements: [Achievement]

    private var earnedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "Achievements"))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)

                    Text(String(localized: "\(earnedCount)/\(achievements.count) earned"))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(palette.accentSoft)
                        .frame(width: 50, height: 50)

                    Text(String(earnedCount))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(palette.accent)
                }
            }

            if achievements.isEmpty {
                Text(String(localized: "New achievements will appear here as you use the app."))
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(palette.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(achievements) { achievement in
                            AchievementBadgeView(
                                achievement: achievement,
                                palette: palette
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .financeCard(palette: palette)
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement
    let palette: FinanceTheme.Palette

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? Color.yellow.opacity(0.15) : palette.accentSoft.opacity(0.5))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(achievement.isEarned ? Color.yellow : palette.secondaryInk)
            }

            Text(achievement.title)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(achievement.isEarned ? palette.ink : palette.secondaryInk)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)

            if achievement.isEarned {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)

                    Text(String(localized: "Earned"))
                        .font(.system(size: 9, design: .rounded).weight(.bold))
                        .foregroundStyle(.green)
                }
            } else {
                Text(String(localized: "Locked"))
                    .font(.system(size: 9, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.secondaryInk)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(achievement.isEarned ? Color.yellow.opacity(0.06) : palette.cardBackground)
        )
    }
}
