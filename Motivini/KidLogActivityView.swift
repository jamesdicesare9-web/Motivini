//
//  KidLogActivityView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import SwiftUI

struct KidLogActivityView: View {
    @EnvironmentObject var app: AppViewModel
    let child: FamilyMember
    @State private var selectedCategory: Category? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Activity").font(.title2).bold()

            if let fam = app.selectedFamily {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(fam.categories) { c in
                        Button {
                            log(category: c, fam: fam)
                        } label: {
                            VStack(spacing: 6) {
                                Text(c.emoji ?? "⬜️").font(.largeTitle)
                                Text(c.name).bold()
                                Text("+\(c.pointValue) after \(c.targetCount)").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(14)
                        }
                    }
                }
            } else {
                Text("No family").foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func log(category: Category, fam: Family) {
        var f = fam
        // child logging -> needs approval
        f.pendingApprovals.append(
            Approval(id: UUID(), kind: .activity, taskId: nil,
                     memberId: child.id, categoryId: category.id,
                     submittedById: child.id, submittedAt: Date())
        )
        f.activityLog.append(
            ActivityLogEntry(id: UUID(), date: Date(), memberId: child.id,
                             description: "Activity submitted: \(category.name)",
                             categoryId: category.id)
        )
        Task { await app.saveFamily(f) }
    }
}
