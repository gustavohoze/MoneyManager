import SwiftUI

struct SettingsAchievementsDetailPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var achievementService = AchievementService()
    let palette: FinanceTheme.Palette

    private var allAchievements: [Achievement] {
        achievementService.getEarnedAchievements()
    }

    private var earnedAchievements: [Achievement] {
        allAchievements.filter { $0.isEarned }
    }

    private var lockedAchievements: [Achievement] {
        allAchievements.filter { !$0.isEarned }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Earned Section
                if !earnedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(palette.accent)
                            Text(String(localized: "Earned Achievements"))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)
                        }

                        VStack(spacing: 10) {
                            ForEach(earnedAchievements) { achievement in
                                HStack(spacing: 12) {
                                    Image(systemName: achievement.icon)
                                        .font(.system(.title3).weight(.semibold))
                                        .foregroundStyle(palette.accent)
                                        .frame(width: 40, height: 40)
                                        .background(palette.accentSoft)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(achievement.title)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(palette.ink)
                                        Text(achievement.description)
                                            .font(.caption)
                                            .foregroundStyle(palette.secondaryInk)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 6) {
                                        if let earnedDate = achievement.earnedDate {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(formattedDate(earnedDate))
                                                    .font(.caption2)
                                                    .foregroundStyle(palette.secondaryInk)
                                            }
                                        }

                                        Button {
                                            achievementService.selectedAchievementId = achievement.id
                                        } label: {
                                            Image(systemName: achievementService.selectedAchievementId == achievement.id ? "checkmark.circle.fill" : "circle")
                                                .font(.system(.subheadline))
                                                .foregroundStyle(palette.accent)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(palette.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(palette.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .financeCard(palette: palette)
                }

                // Locked Section
                if !lockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(palette.secondaryInk)
                            Text(String(localized: "Locked Achievements"))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(palette.ink)
                        }

                        VStack(spacing: 10) {
                            ForEach(lockedAchievements) { achievement in
                                HStack(spacing: 12) {
                                    Image(systemName: achievement.icon)
                                        .font(.system(.title3).weight(.semibold))
                                        .foregroundStyle(palette.secondaryInk)
                                        .opacity(0.4)
                                        .frame(width: 40, height: 40)
                                        .background(palette.cardBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(achievement.title)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(palette.ink)
                                        Text(achievement.description)
                                            .font(.caption)
                                            .foregroundStyle(palette.secondaryInk)
                                            .lineLimit(2)
                                    }

                                    Spacer()

                                    Image(systemName: "lock.circle")
                                        .foregroundStyle(palette.secondaryInk)
                                        .opacity(0.5)
                                }
                                .padding(12)
                                .background(palette.cardBackground.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(palette.cardBorder.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .financeCard(palette: palette)
                }

                if earnedAchievements.isEmpty && lockedAchievements.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(palette.accentSoft)
                        Text(String(localized: "No achievements yet"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(palette.ink)
                        Text(String(localized: "Keep using the app to unlock achievements!"))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .financeCard(palette: palette)
                }
            }
            .padding(16)
        }
        .background(FinanceTheme.pageBackground(for: colorScheme))
        .navigationTitle(String(localized: "Achievements"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
