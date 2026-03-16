//
//  MoneyManagerApp.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
import CoreData

@main
struct MoneyManagerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var persistenceStoreManager = PersistenceStoreManager(controller: PersistenceController.shared)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceStoreManager.viewContext)
                .environmentObject(persistenceStoreManager)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                persistenceStoreManager.refreshIfNeeded()
            }
        }
    }
}
