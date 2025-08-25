//
//  ApprovalsView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI

struct ApprovalsView: View {
    @EnvironmentObject var app: AppModel
    @State private var pin: String = ""
    @State private var showPINSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !app.isParentMode {
                    VStack(spacing: 12) {
                        Text("Parent Mode is locked")
                            .font(.headline)
                        Button {
                            showPINSheet = true
                        } label: {
                            Label("Unlock with PIN", systemImage: "lock.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                    .padding()
                } else {
                    List {
                        Section("Pending Logs") {
                            let allPending = app.pendingLogs(for: nil)
                            if allPending.isEmpty {
                                Text("Nothing pending right now.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(allPending) { log in
                                    if let child = app.members.first(where: {$0.id == log.childId}),
                                       let template = app.seriesTemplates.first(where: {$0.id == log.templateId}) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(template.title).font(.headline)
                                                Spacer()
                                                Text(child.name).font(.subheadline).foregroundStyle(.secondary)
                                            }
                                            Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                            HStack {
                                                Button {
                                                    app.parentApprove(log: log)
                                                } label: {
                                                    Label("Approve", systemImage: "checkmark.circle.fill")
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(.green)

                                                Button {
                                                    app.parentReject(log: log)
                                                } label: {
                                                    Label("Reject", systemImage: "xmark.circle.fill")
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(.red)
                                            }
                                        }
                                        .padding(8)
                                        .background(.ultraThickMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                app.lockParentMode()
                            } label: {
                                Label("Lock", systemImage: "lock.open.fill")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Approvals")
        }
        .sheet(isPresented: $showPINSheet) {
            PINUnlockSheet(pin: $pin) { tryPin in
                if app.unlockParentMode(pin: tryPin) {
                    showPINSheet = false
                }
            }
        }
    }
}

private struct PINUnlockSheet: View {
    @Binding var pin: String
    var onSubmit: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Enter Parent PIN") {
                    SecureField("PIN", text: $pin)
                        .keyboardType(.numberPad)
                }
                Section {
                    Button {
                        onSubmit(pin)
                        pin = ""
                    } label: {
                        Label("Unlock", systemImage: "key.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
            .navigationTitle("Parent PIN")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { pin = "" }
                }
            }
        }
    }
}
