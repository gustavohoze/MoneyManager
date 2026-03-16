//
//  ContentView.swift
//  MoneyManager
//
//  Created by Gustavo Hoze on 16/03/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Milestone 0") {
                    Label("Project structure scaffolded", systemImage: "checkmark.circle.fill")
                    Label("Core Data + CloudKit container configured", systemImage: "checkmark.circle.fill")
                    Label("Base entities added: Account, Transaction, Merchant, Category", systemImage: "checkmark.circle.fill")
                }
            }
            .navigationTitle("MoneyManager")
        }
    }
}

#Preview {
    ContentView()
}
