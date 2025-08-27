//
//  MyPointsView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import SwiftUI

struct MyPointsView: View {
    @EnvironmentObject var app: AppViewModel
    let child: FamilyMember

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Points").font(.title2).bold()

            if let fam = app.selectedFamily {
                let pts = fam.memberPoints[child.id] ?? 0
                let dollars = fam.pointsConfig.dollars(forPoints: pts)

                HStack {
                    Label("\(pts) pts", systemImage: "trophy.fill")
                    Spacer()
                    Label(String(format: "$%.2f", dollars), systemImage: "dollarsign.circle")
                }
                .font(.title3)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(14)

                Text("Recent").font(.headline)
                List {
                    ForEach(
                        fam.activityLog
                            .filter { $0.memberId == child.id }
                            .sorted { $0.date > $1.date }
                            .prefix(20)
                    ) { entry in
                        HStack {
                            Text(entry.description)
                            Spacer()
                            Text(entry.date, style: .date)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No family selected").foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
