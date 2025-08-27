//
//  MyTasksView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import SwiftUI

struct MyTasksView: View {
    @EnvironmentObject var app: AppViewModel
    let child: FamilyMember

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(child.name)").font(.title2).bold()

            if let fam = app.selectedFamily {
                let mine = fam.tasks.filter { $0.assigneeId == child.id && !$0.isCompleted }
                if mine.isEmpty {
                    Text("Nothing assigned yet 👍").foregroundStyle(.secondary)
                }
                List {
                    ForEach(mine) { t in
                        TaskRow(task: t) // child pressing "Complete" creates a pending approval
                    }
                }
            } else {
                Text("No family").foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
