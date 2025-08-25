import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Member.name)]) private var members: [Member]
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]

    // member form
    @State private var name = ""
    @State private var role: Role = .child
    @State private var emoji = "🙂"

    // category form
    @State private var catName = ""
    @State private var catIcon = "✅"
    @State private var target = 5
    @State private var award = 2

    // parent PIN
    @AppStorage("parentPIN") private var parentPIN: String = "1234"
    @State private var newPin = ""
    @State private var confirmPin = ""

    var body: some View {
        ParentGate {
            NavigationStack {
                Form {
                    Section("Add Member") {
                        TextField("Name", text: $name)
                        Picker("Role", selection: $role) {
                            ForEach(Role.allCases) { r in Text(r.label).tag(r) }
                        }
                        TextField("Avatar emoji", text: $emoji)
                        Button("Add Member") { addMember() }
                            .disabled(name.isEmpty)
                    }

                    Section("Members") {
                        ForEach(members) { m in
                            HStack {
                                Text(m.avatarEmoji)
                                Text("\(m.name) • \(m.role.label)")
                                Spacer()
                                Text("\(m.points) pts").foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteMembers)
                    }

                    Section("Add Category") {
                        TextField("Name", text: $catName)
                        TextField("Icon (emoji or SF Symbol)", text: $catIcon)
                        Stepper("Target count: \(target)", value: $target, in: 1...50)
                        Stepper("Points per award: \(award)", value: $award, in: 0...100)
                        Button("Add Category") { addCategory() }
                            .disabled(catName.isEmpty)
                    }

                    Section("Categories") {
                        ForEach(categories) { c in
                            VStack(alignment: .leading) {
                                Text("\(c.icon) \(c.name)")
                                Text("\(c.pointsPerAward) pts every \(c.targetCount)x")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }

                    Section("Parent PIN") {
                        Text("Current PIN: ••••")
                            .foregroundStyle(.secondary)
                        SecureField("New 4-digit PIN", text: $newPin)
                            .keyboardType(.numberPad)
                        SecureField("Confirm PIN", text: $confirmPin)
                            .keyboardType(.numberPad)
                        Button("Update PIN") {
                            guard newPin.count == 4, newPin.allSatisfy(\.isNumber) else { return }
                            guard newPin == confirmPin else { return }
                            parentPIN = newPin
                            newPin = ""; confirmPin = ""
                            Haptics.success()
                        }
                        .disabled(newPin.isEmpty || confirmPin.isEmpty)
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }

    private func addMember() {
        let m = Member(name: name, role: role, avatarEmoji: emoji)
        context.insert(m)
        try? context.save()
        name = ""; emoji = role == .parent ? "🧑‍🍼" : "🧒"
        Haptics.success()
    }

    private func addCategory() {
        let c = Category(name: catName, icon: catIcon, targetCount: target, pointsPerAward: award)
        context.insert(c)
        try? context.save()
        catName = ""; catIcon = "✅"; target = 5; award = 2
        Haptics.success()
    }

    private func deleteMembers(at offsets: IndexSet) {
        for i in offsets { context.delete(members[i]) }
        try? context.save()
        Haptics.warning()
    }

    private func deleteCategories(at offsets: IndexSet) {
        for i in offsets { context.delete(categories[i]) }
        try? context.save()
        Haptics.warning()
    }
}
