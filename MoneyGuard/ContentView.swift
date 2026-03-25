//
//  ContentView.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @AppStorage("onboarding.openAddTransactionAfterCompletion") private var openAddTransactionAfterCompletion = false
    @AppStorage("settings.lockWithFaceID") private var lockWithFaceID = false

    @State private var hasCheckedCloudKitOnLaunch = false
    @State private var isShowingCloudKitLaunchPrompt = false
    @State private var isShowingRestartPrompt = false
    @State private var isAuthenticating = false
    @State private var requiresAuthentication = false
    private let analytics = AnalyticsServiceFactory.makeDefault()

    private var shouldShowLockScreen: Bool {
        lockWithFaceID && requiresAuthentication
    }

    private var palette: FinanceTheme.Palette {
        FinanceTheme.palette(for: colorScheme)
    }

    var body: some View {
        ZStack {
            appRootContent

            if shouldShowLockScreen {
                appLockOverlay
            }
        }
        .environment(\.managedObjectContext, persistenceStoreManager.viewContext)
        .onAppear {
            guard !hasCheckedCloudKitOnLaunch else { return }
            hasCheckedCloudKitOnLaunch = true

            guard onboardingCompleted else { return }

            guard CloudKitConstants.isSyncEnabledForCurrentRuntime else { return }

            if persistenceStoreManager.controller.activeStoreMode != .cloudKitSQLite {
                isShowingCloudKitLaunchPrompt = true
            }

            if lockWithFaceID {
                requiresAuthentication = true
                Task { await authenticateIfNeeded() }
            }
        }
        .onChange(of: lockWithFaceID) { _, isEnabled in
            if isEnabled {
                requiresAuthentication = true
                Task { await authenticateIfNeeded() }
            } else {
                requiresAuthentication = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard lockWithFaceID else {
                return
            }

            if newPhase == .background {
                requiresAuthentication = true
            }

            if newPhase == .active, requiresAuthentication {
                Task { await authenticateIfNeeded() }
            }
        }
        .alert(String(localized: "Enable iCloud Sync?"), isPresented: $isShowingCloudKitLaunchPrompt) {
            Button(String(localized: "Not Now"), role: .cancel) {}
            Button(String(localized: "Enable iCloud Sync")) {
                let outcome = persistenceStoreManager.requestCloudKitUpgrade()
                if outcome == .queuedForNextLaunch {
                    isShowingRestartPrompt = true
                }
            }
        } message: {
            Text(String(localized: "CloudKit sync is currently off. Enable it now, then restart the app to complete setup."))
        }
        .alert(String(localized: "Restart Required"), isPresented: $isShowingRestartPrompt) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            Text(String(localized: "Please restart the app so CloudKit sync can be activated."))
        }
    }

    private var appRootContent: some View {
        Group {
            if showMilestoneZeroExamples {
                NavigationStack {
                    MilestoneZeroExamplesView()
                }
            } else if !onboardingCompleted {
                LeanOnboardingFlowView {
                    onboardingCompleted = true
                }
            } else {
                MilestoneOneRootView(
                    context: persistenceStoreManager.viewContext,
                    initialTab: openAddTransactionAfterCompletion ? .add : .dashboard,
                    autoFocusAddAmountOnLaunch: openAddTransactionAfterCompletion,
                    onInitialLaunchHandled: {
                        openAddTransactionAfterCompletion = false
                    }
                )
                .onOpenURL { url in
                    if url.scheme == "moneyguard" && url.host == "add-transaction" {
                        analytics.track(.lockscreenLoggingUsed)
                        openAddTransactionAfterCompletion = true
                    }
                }
            }
        }
    }

    private var appLockOverlay: some View {
        ZStack {
            FinanceTheme.pageBackground(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "faceid")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .frame(width: 56, height: 56)
                    .background(palette.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(String(localized: "MoneyManager Locked"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(palette.ink)

                Text(String(localized: "Authenticate to continue using the app."))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(palette.secondaryInk)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await authenticateIfNeeded() }
                } label: {
                    HStack(spacing: 8) {
                        if isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isAuthenticating ? String(localized: "Unlocking...") : String(localized: "Unlock with Face ID"))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(palette.accent)
                    )
                }
                .disabled(isAuthenticating)
            }
            .padding(20)
            .financeCard(palette: palette)
            .padding(.horizontal, 24)
        }
    }

    @MainActor
    private func authenticateIfNeeded() async {
        guard lockWithFaceID, requiresAuthentication else {
            return
        }

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Not now")

        let reason = String(localized: "Unlock MoneyManager to view your financial data.")
        var error: NSError?

        let success: Bool
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            success = (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
        } else {
            success = false
        }

        if success {
            requiresAuthentication = false
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    .environmentObject(PersistenceStoreManager(controller: PersistenceController.shared))
}
