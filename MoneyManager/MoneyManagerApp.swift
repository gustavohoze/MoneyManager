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
    @StateObject private var persistenceStoreManager = PersistenceStoreManager(controller: PersistenceController.shared)

    init() {
        CloudSyncedPreferencesBridge.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceStoreManager.viewContext)
                .environmentObject(persistenceStoreManager)
        }
    }
}
