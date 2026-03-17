//
//  ContentView.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @AppStorage("debug.showMilestoneZeroExamples") private var showMilestoneZeroExamples = false

    var body: some View {
        if showMilestoneZeroExamples {
            NavigationStack {
                MilestoneZeroExamplesView()
            }
        } else {
            MilestoneOneRootView(context: context)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    .environmentObject(PersistenceStoreManager(controller: PersistenceController.shared))
}
