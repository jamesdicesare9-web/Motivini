//
//  SettingsView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppModel
    @State private var pinInput: String = ""
    @State private var newChildName = ""
    @State private var newChildAvatar = "face.smiling"

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent Mode") {
                    HStack {
                        SecureField("Change Parent PIN", text: $pinInput)
                            .keyboardType(.numberPad)
                        Button("Save") {
                            guard !pinInput.isEmpty else { return }
                            app.parentPIN = pinInput
                            app.persist()
                            pinInput = ""
                            Haptics.success()
                        }
                    }
                    Text("Default PIN is 1234. Unlock/lock from the Approvals tab.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Family Members") {
                    ForEach(app.members) { m in
                        HStack {
                            Text(m.avatar)
                            Text(m.name)
                            Spacer()
                            Text(m.role == .parent ? "Parent" : "Child")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { idxSet in
                        let toDelete = idxSet.map { app.members[$0] }
                        let remainingParents = app.members.filter { $0.role == .parent && !toDelete.contains($0) }
                        let remainingChildren = app.members.filter { $0.role == .child && !toDelete.contains($0) }
                        guard !remainingParents.isEmpty, !remainingChildren.isEmpty else { return }
                        app.members.remove(atOffsets: idxSet)
                        app.persist()
                    }

                    HStack {
                        TextField("New child name", text: $newChildName)
                        TextField("Avatar (emoji or SF symbol)", text: $newChildAvatar)
                        Button("Add") {
                            guard !newChildName.isEmpty else { return }
                            let kid = Member(name: newChildName, role: .child, avatar: newChildAvatar)
                            app.members.append(kid)
                            if app.selectedChildId == nil { app.selectedChildId = kid.id }
                            app.persist()
                            newChildName = ""
                            Haptics.success()
                        }
                    }
                }

                Section("Series Templates") {
                    if let _ = app.selectedChildId {
                        ForEach(app.seriesTemplates) { t in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(t.title).bold()
                                    Spacer()
                                    Text("\(t.threshold)× → +\(t.awardPoints)")
                                }
                                Text("\(t.category) • \(t.window.rawValue.capitalized) • Limit \(t.perDayLimit)x/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Assigned to \(assigneesText(t))")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { idx in
                            app.seriesTemplates.remove(atOffsets: idx)
                            app.persist()
                        }

                        NavigationLink("Create New Series") {
                            CreateSeriesView()
                        }
                    } else {
                        Text("Select a child above to view series.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        app.seed()
                        app.persist()
                    } label: {
                        Label("Reset to Seed Examples", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("About") {
                    Text("Motivini Stage 0 • Local-only\nPunch-card points with parent approval, rewards with photos, liquid-glass UI & haptics.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func assigneesText(_ t: SeriesTemplate) -> String {
        let names = app.members.filter { t.appliesToMemberIds.contains($0.id) }.map(\.name)
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }
}

struct CreateSeriesView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var category = "General"
    @State private var threshold = "5"
    @State private var award = "2"
    @State private var window: SeriesWindow = .weekly
    @State private var perDayLimit = "1"
    @State private var selectedKids: Set<UUID> = []

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Title (e.g., Make Bed)", text: $title)
                TextField("Category (e.g., Room)", text: $category)
            }
            Section("Rules") {
                TextField("Threshold (e.g., 5)", text: $threshold).keyboardType(.numberPad)
                TextField("Award Points (e.g., 2)", text: $award).keyboardType(.numberPad)
                Picker("Window", selection: $window) {
                    ForEach(SeriesWindow.allCases) { w in
                        Text(w.rawValue.capitalized).tag(w)
                    }
                }
                TextField("Per-Day Limit (e.g., 1)", text: $perDayLimit).keyboardType(.numberPad)
            }
            Section("Assign to Children") {
                let kids = app.children()
                if kids.isEmpty {
                    Text("No children yet. Add one in Settings.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(kids) { kid in
                        Toggle(isOn: Binding(get: { selectedKids.contains(kid.id) }, set: { val in
                            if val { selectedKids.insert(kid.id) } else { selectedKids.remove(kid.id) }
                        })) {
                            Text(kid.name)
                        }
                    }
                }
            }

            Section {
                Button {
                    guard let th = Int(threshold), let aw = Int(award), let pdl = Int(perDayLimit), !title.isEmpty, !selectedKids.isEmpty else { return }
                    let template = SeriesTemplate(title: title, category: category.isEmpty ? "General" : category, threshold: th, awardPoints: aw, window: window, perDayLimit: pdl, appliesToMemberIds: Array(selectedKids))
                    app.seriesTemplates.append(template)
                    app.persist()
                    Haptics.success()
                    dismiss()
                } label: {
                    Label("Save Series", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .navigationTitle("New Series")
    }
}
