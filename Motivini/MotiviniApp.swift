//
//  MotiviniApp.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI
import SwiftData

@main
struct MotiviniApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Member.self, Category.self, Completion.self, Purchase.self])
    }
}
