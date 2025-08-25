//
//  RootView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            SeriesListView()
                .tabItem { Label("Punch Cards", systemImage: "rectangle.grid.2x2.fill") }

            ApprovalsView()
                .tabItem { Label("Approvals", systemImage: "checkmark.seal.fill") }

            RewardsView()
                .tabItem { Label("Rewards", systemImage: "gift.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.purple)
    }
}
