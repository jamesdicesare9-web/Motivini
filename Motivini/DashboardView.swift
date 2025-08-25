//
//  DashboardView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // Child selector
                GlassCard {
                    HStack {
                        Text("Child")
                            .font(.headline)
                        Spacer()
                        Picker("Child", selection: Binding<UUID?>(
                            get: { app.selectedChildId },
                            set: { app.selectedChildId = $0; app.persist() }
                        )) {
                            ForEach(app.children()) { c in
                                Text(c.name).tag(Optional.some(c.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Balance card
                if let childId = app.selectedChildId, let child = app.members.first(where: {$0.id == childId}) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(child.name)’s Balance")
                                .font(.title3).bold()
                            Text("$\(app.balance(for: childId))")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                            Text("1 point = $1. Points only mint when a punch-card is completed.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Quick summary of series progress
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Week’s Punch Cards")
                            .font(.headline)
                        if let childId = app.selectedChildId {
                            ForEach(app.seriesTemplates.filter{ $0.appliesToMemberIds.contains(childId) }) { template in
                                SeriesProgressRow(template: template, childId: childId)
                                Divider().opacity(0.2)
                            }
                        } else {
                            Text("Add or select a child in Settings.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Pending count
                GlassCard {
                    HStack {
                        Text("Pending Approvals")
                            .font(.headline)
                        Spacer()
                        Text("\(app.pendingLogs(for: nil).count)")
                            .font(.title2).bold()
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Motivini")
    }
}

private struct SeriesProgressRow: View {
    @EnvironmentObject var app: AppModel
    let template: SeriesTemplate
    let childId: UUID

    var body: some View {
        let inst = app.instance(for: childId, template: template)
        HStack(spacing: 12) {
            ZStack {
                Circle().stroke(lineWidth: 8).foregroundStyle(.gray.opacity(0.2))
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(inst.approvedCount) / Double(template.threshold), 1.0)))
                    .stroke(.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(min(inst.approvedCount, template.threshold))/\(template.threshold)")
                    .font(.caption).bold()
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title).font(.headline)
                Text("\(template.category) • \(template.window.rawValue.capitalized) • Limit \(template.perDayLimit)x/day")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if inst.mintedAtThresholds.contains(template.threshold) {
                Label("+\(template.awardPoints)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }
        }
    }
}
