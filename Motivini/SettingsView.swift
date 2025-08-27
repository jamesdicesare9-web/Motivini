import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var notificationsEnabled = false

    var body: some View {
        Form {
            // Account
            if let acc = app.currentAccount {
                Section("Account") {
                    Text(acc.displayName)
                    if !acc.email.isEmpty {
                        Text(acc.email).foregroundStyle(.secondary)
                    }
                    Button("Sign Out", role: .destructive) { app.signOut() }
                }

                // Family selection
                Section("Family") {
                    if acc.families.isEmpty {
                        Text("No families yet")
                    } else {
                        ForEach(acc.families, id: \.self) { f in
                            HStack {
                                Text(f.name)
                                Spacer()
                                if app.selectedFamily?.id == f.id {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { Task { await app.switchFamily(to: f) } }
                        }
                    }
                }
            }

            // Push notifications (stubbed)
            Section("Notifications") {
                Toggle("Enable Push Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, _ in
                        Task { _ = await PushNotificationManager.shared.requestPermission() }
                    }
            }

            // Points & cash conversion
            if let fam = app.selectedFamily {
                Section("Points & Rewards") {
                    // Bind directly to a computed Binding that writes the updated family through the view model
                    let pointsBinding = Binding<Double>(
                        get: { fam.pointsConfig.pointsPerDollar },
                        set: { newVal in
                            var f = fam
                            f.pointsConfig.pointsPerDollar = max(0.1, newVal)
                            Task { await app.saveFamily(f) }
                        }
                    )

                    Stepper(value: pointsBinding, in: 0.1...100, step: 0.5) {
                        Text("Points per $1: \(String(format: "%.1f", fam.pointsConfig.pointsPerDollar))")
                    }

                    if
                        let me = fam.members.first(where: { $0.name == app.currentAccount?.displayName }),
                        let pts = fam.memberPoints[me.id]
                    {
                        let dollars = fam.pointsConfig.dollars(forPoints: pts)
                        Text("Your Balance: \(pts) pts  (≈ $\(String(format: "%.2f", dollars)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("About") { Text("Motivini v1.2 • Local-first MVP") }
        }
    }
}
