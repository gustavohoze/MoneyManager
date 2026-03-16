//
//  MoneyManagerApp.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
internal import CoreData

@main
struct MoneyManagerApp: App {
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
