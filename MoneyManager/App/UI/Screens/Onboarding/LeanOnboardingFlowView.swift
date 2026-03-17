import SwiftUI
import UserNotifications

struct LeanOnboardingFlowView: View {
    enum Step: Int, CaseIterable {
        case welcome
        case currency
        case notifications
    }

    @State private var step: Step = .welcome
    @State private var selectedCurrencyCode: String = AppCurrency.currentCode
    @State private var didTrackStart = false
    @Environment(\.colorScheme) private var colorScheme

    private let analytics: AnalyticsTracking = AnalyticsServiceFactory.makeDefault()
    let onComplete: () -> Void

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FinanceTheme.pageBackground(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    topHeader

                    Group {
                        switch step {
                        case .welcome:
                            welcomeContent
                        case .currency:
                            currencyContent
                        case .notifications:
                            notificationsContent
                        }
                    }

                    Spacer(minLength: 8)

                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            guard !didTrackStart else { return }
            didTrackStart = true
            analytics.track(.onboardingStarted)
        }
    }

    private var topHeader: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Welcome"))
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(palette.ink)
                    Text(String(localized: "Step \(step.rawValue + 1) of \(Step.allCases.count)"))
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(palette.secondaryInk)
                }

                Spacer()

                Image(systemName: stepBadgeIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 34, height: 34)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.rawValue) { item in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(item.rawValue <= step.rawValue ? palette.accent : palette.cardBorder)
                        .frame(height: 5)
                }
            }
        }
        .financeCard(palette: palette)
    }

    private var stepBadgeIcon: String {
        switch step {
        case .welcome:
            return "hand.wave.fill"
        case .currency:
            return "banknote.fill"
        case .notifications:
            return "bell.badge.fill"
        }
    }

    private var welcomeContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingArtwork(name: "OnboardingWelcomeArt")

            Text(String(localized: "Track money with clarity"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(palette.ink)

            Text(String(localized: "Start quickly with a simple flow, then manage everything from Settings later."))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(palette.secondaryInk)

            VStack(alignment: .leading, spacing: 10) {
                OnboardingBullet(text: String(localized: "Fast daily expense logging"), palette: palette)
                OnboardingBullet(text: String(localized: "Clear spending insights"), palette: palette)
                OnboardingBullet(text: String(localized: "Settings stay flexible later"), palette: palette)
            }
            .financeCard(palette: palette)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currencyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingArtwork(name: "OnboardingCurrencyArt")

            Text(String(localized: "Choose your default currency"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(palette.ink)

            Text(String(localized: "This will be used for your first transactions and budget screens."))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(palette.secondaryInk)

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Currency"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(palette.secondaryInk)

                Picker(String(localized: "Currency"), selection: $selectedCurrencyCode) {
                    ForEach(AppCurrency.allCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .pickerStyle(.menu)
                .tint(palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .financeCard(palette: palette)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            onboardingArtwork(name: "OnboardingNotificationArt")

            Text(String(localized: "Enable reminders?"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(palette.ink)
            Text(String(localized: "You can get helpful alerts for daily spending and weekly summaries. You can change this anytime in Settings."))
                .font(.system(.body, design: .rounded))
                .foregroundStyle(palette.secondaryInk)

            VStack(alignment: .leading, spacing: 10) {
                OnboardingBullet(text: String(localized: "Daily warning for safe spending limits"), palette: palette)
                OnboardingBullet(text: String(localized: "Weekly summary to track progress"), palette: palette)
                OnboardingBullet(text: String(localized: "Fully optional and configurable later"), palette: palette)
            }
            .financeCard(palette: palette)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if step != .welcome {
                Button(String(localized: "Back")) {
                    moveBack()
                }
                .buttonStyle(OnboardingActionButtonStyle(
                    palette: palette,
                    role: .secondary
                ))
            }

            Spacer()

            switch step {
            case .welcome, .currency:
                Button(String(localized: "Continue")) {
                    moveForward()
                }
                .buttonStyle(OnboardingActionButtonStyle(
                    palette: palette,
                    role: .primary
                ))
            case .notifications:
                Button(String(localized: "Not now")) {
                    completeOnboarding()
                }
                .buttonStyle(OnboardingActionButtonStyle(
                    palette: palette,
                    role: .secondary
                ))

                Button(String(localized: "Allow")) {
                    requestNotificationPermissionAndFinish()
                }
                .buttonStyle(OnboardingActionButtonStyle(
                    palette: palette,
                    role: .primary
                ))
            }
        }
    }

    private func moveBack() {
        let previousRawValue = max(step.rawValue - 1, Step.welcome.rawValue)
        step = Step(rawValue: previousRawValue) ?? .welcome
    }

    private func moveForward() {
        if step == .currency {
            UserDefaults.standard.set(selectedCurrencyCode, forKey: AppCurrency.settingsKey)
        }

        let nextRawValue = min(step.rawValue + 1, Step.notifications.rawValue)
        step = Step(rawValue: nextRawValue) ?? .notifications
    }

    private func requestNotificationPermissionAndFinish() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                completeOnboarding()
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding.completed")
        UserDefaults.standard.set(true, forKey: "onboarding.openAddTransactionAfterCompletion")
        analytics.track(.onboardingCompleted)
        analytics.flush(completion: nil)
        onComplete()
    }

    private func onboardingArtwork(name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .padding(.horizontal, 4)
            .padding(.top, 4)
    }
}

private struct OnboardingBullet: View {
    let text: String
    let palette: FinanceTheme.Palette

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(palette.accent)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(palette.ink)
            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingActionButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
    }

    let palette: FinanceTheme.Palette
    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        return configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundStyle)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: isPressed)
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return .white
        case .secondary:
            return palette.ink
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary:
            return Color.clear
        case .secondary:
            return palette.cardBorder
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch role {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [palette.heroStart, palette.heroEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(palette.cardBackground)
        }
    }
}
