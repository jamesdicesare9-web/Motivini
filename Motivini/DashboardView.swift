//
//  DashboardView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: [SortDescriptor(\Member.name)]) private var members: [Member]
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]

    var body: some View {
        NavigationStack {
            List {
                Section("Family Balances") {
                    ForEach(members) { m in
                        HStack {
                            Text(m.avatarEmoji).font(.title2)
                            Text(m.name).font(.headline)
                            Spacer()
                            Text("\(m.points) pts").bold()
                        }
                    }
                }

                Section("Categories") {
                    ForEach(categories) { c in
                        HStack {
                            Text("\(c.icon) \(c.name)")
                            Spacer()
                            Text("\(c.pointsPerAward) pts / \(c.targetCount)x")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Motivini")
        }
    }
}
