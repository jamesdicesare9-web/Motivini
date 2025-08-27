import SwiftUI

struct MembersView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var name = ""
    @State private var avatar = "👧"
    @State private var role: Role = .child

    // child credentials form
    @State private var credUsername = ""
    @State private var credEmail = ""
    @State private var credPassword = ""
    @State private var selectedMemberForCreds: FamilyMember? = nil

    private var canEdit: Bool {
        guard let fam = app.selectedFamily, let acc = app.currentAccount else { return false }
        let me = fam.members.first(where: { $0.name == acc.displayName })
        return me?.role != .child
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Members").font(.title2).bold()
            if let fam = app.selectedFamily {
                List {
                    ForEach(fam.members) { m in
                        HStack { Text(m.avatar); Text(m.name).bold(); Spacer(); Text(m.role.rawValue.capitalized).foregroundStyle(.secondary) }
                    }
                    .onDelete(perform: canEdit ? delete : nil)
                }

                if canEdit {
                    Divider()
                    Text("Add Member").font(.headline)
                    HStack {
                        TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                        Menu(avatar) {
                            ForEach(["👧","🧒","👦","👩","👨","👶","🧑🏻","🧑🏽","🧑🏿"], id: \.self) { a in Button(a) { avatar = a } }
                        }
                        Picker("Role", selection: $role) { ForEach(Role.allCases) { Text($0.rawValue.capitalized).tag($0) } }
                        Button("Add") { add(fam: fam) }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Divider()
                    Text("Child Login Credentials").font(.headline)
                    HStack {
                        Menu(selectedMemberForCreds?.name ?? "Choose Child") {
                            ForEach(fam.members.filter { $0.role == .child }) { m in Button(m.name) { selectedMemberForCreds = m } }
                        }
                        TextField("Username", text: $credUsername).textInputAutocapitalization(.never).autocorrectionDisabled()
                        TextField("Email (optional)", text: $credEmail).textInputAutocapitalization(.never)
                        SecureField("Password", text: $credPassword)
                        Button("Save") { saveCreds() }
                            .disabled(selectedMemberForCreds == nil || credUsername.isEmpty || credPassword.isEmpty)
                    }
                    Text("Children can sign in on this device using the Child tab on the login screen.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Child profiles are view-only for Members.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func add(fam: Family) {
        var f = fam
        f.members.append(FamilyMember(id: UUID(), name: name, avatar: avatar, role: role))
        Task { await app.saveFamily(f) }
        name = ""; avatar = "👧"; role = .child
    }

    private func saveCreds() {
        guard var f = app.selectedFamily, let child = selectedMemberForCreds else { return }
        Task {
            await ChildAuthService.shared.upsertCredential(for: &f,
                                                           memberId: child.id,
                                                           username: credUsername,
                                                           email: credEmail.isEmpty ? nil : credEmail,
                                                           password: credPassword)
            await app.saveFamily(f)
            credUsername = ""; credEmail = ""; credPassword = ""; selectedMemberForCreds = nil
        }
    }

    private func delete(at offsets: IndexSet) {
        guard var f = app.selectedFamily else { return }
        f.members.remove(atOffsets: offsets)
        Task { await app.saveFamily(f) }
    }
}
