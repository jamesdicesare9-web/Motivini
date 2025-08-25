//
//  SeriesListView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct SeriesListView: View {
    @EnvironmentObject var app: AppModel
    @State private var note: String = ""

    var body: some View {
        VStack {
            if let childId = app.selectedChildId {
                List {
                    Section {
                        ForEach(app.seriesTemplates.filter { $0.appliesToMemberIds.contains(childId) }) { template in
                            GlassRow {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(template.title).font(.headline)
                                        Spacer()
                                        Text("\(template.threshold)× → +\(template.awardPoints)")
                                            .font(.subheadline).bold()
                                    }
                                    Text("\(template.category) • \(template.window.rawValue.capitalized) • Limit \(template.perDayLimit)x/day")
                                        .font(.caption).foregroundStyle(.secondary)

                                    let inst = app.instance(for: childId, template: template)
                                    ProgressView(value: Double(inst.approvedCount), total: Double(template.threshold))
                                        .tint(.purple)

                                    HStack {
                                        Button {
                                            app.childLogCompletion(childId: childId, template: template, note: nil)
                                        } label: {
                                            Label("Log Completion (needs parent approval)", systemImage: "plus.circle.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.purple)

                                        Spacer()
                                        if inst.mintedAtThresholds.contains(template.threshold) {
                                            Label("Awarded +\(template.awardPoints)", systemImage: "checkmark.seal.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Your Punch Cards")
                    }

                    Section("Pending Status") {
                        let mine = app.pendingLogs(for: childId)
                        if mine.isEmpty {
                            Text("No pending items. Great job!")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(mine) { log in
                                if let template = app.seriesTemplates.first(where: {$0.id == log.templateId}) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(template.title)
                                            Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("Awaiting parent")
                                            .font(.caption).foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            } else {
                Text("Select a child in Settings.")
                    .padding()
            }
        }
        .navigationTitle("Punch Cards")
    }
}

private struct GlassRow<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        GlassCard { content() }
            .listRowBackground(Color.clear)
    }
}
