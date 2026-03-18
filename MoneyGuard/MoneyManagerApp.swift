//
//  MoneyManagerApp.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
import CoreData
import UserNotifications

final class InAppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}

@main
struct MoneyManagerApp: App {
    @StateObject private var persistenceStoreManager = PersistenceStoreManager(controller: PersistenceController.shared)
    private let inAppNotificationDelegate = InAppNotificationDelegate()

    init() {
        CloudSyncedPreferencesBridge.shared.start()
        UNUserNotificationCenter.current().delegate = inAppNotificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceStoreManager.viewContext)
                .environmentObject(persistenceStoreManager)
        }
    }
}
