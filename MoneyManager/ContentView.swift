//
//  ContentView.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject private var persistenceStoreManager: PersistenceStoreManager
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    @AppStorage("onboarding.openAddTransactionAfterCompletion") private var openAddTransactionAfterCompletion = false

    @State private var hasCheckedCloudKitOnLaunch = false
    @State private var isShowingCloudKitLaunchPrompt = false
    @State private var isShowingRestartPrompt = false

    var body: some View {
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
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    .environmentObject(PersistenceStoreManager(controller: PersistenceController.shared))
}
