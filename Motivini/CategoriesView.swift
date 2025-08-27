import SwiftUI

struct CategoriesView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var name = ""
    @State private var emoji: String = ""
    @State private var colorHex = "#2ECC71"
    @State private var pointValue: Int = 1
    @State private var targetCount: Int = 1

    private var canEdit: Bool {
        guard let fam = app.selectedFamily, let acc = app.currentAccount else { return false }
        let me = fam.members.first(where: { $0.name == acc.displayName })
        return me?.role != .child
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories").font(.title2).bold()
            if let fam = app.selectedFamily {
                List {
                    ForEach(fam.categories) { c in
                        HStack(alignment: .top) {
                            Text(c.emoji ?? "⬜️").font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(c.name).bold()
                                Text("Pts: \(c.pointValue) • Target: \(c.targetCount)").font(.caption).foregroundStyle(.secondary)
                                Text(c.colorHex).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            EditCategoryButton(category: c)
                        }
                    }
                    .onDelete(perform: canEdit ? delete : nil)
                }
                if canEdit {
                    Divider()
                    Text("Add Category").font(.headline)
                    VStack(spacing: 8) {
                        TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                        HStack {
                            TextField("Emoji", text: $emoji).textFieldStyle(.roundedBorder).frame(width: 80)
                            Text("Tap to use emoji keyboard").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack {
                            Stepper("Points: \(pointValue)", value: $pointValue, in: 1...100)
                            Stepper("Target: \(targetCount)", value: $targetCount, in: 1...100)
                        }
                        HStack {
                            TextField("#RRGGBB", text: $colorHex).textFieldStyle(.roundedBorder).frame(width: 120)
                            Spacer()
                            Button("Add") { add(fam: fam) }
                                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                } else {
                    Text("Child profiles are view-only for Categories.").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private func add(fam: Family) {
        var f = fam
        let e = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let new = Category(id: UUID(), name: name, emoji: e.isEmpty ? nil : e,
                           colorHex: colorHex, isDefault: false,
                           pointValue: pointValue, targetCount: targetCount)
        f.categories.append(new)
        Task { await app.saveFamily(f) }
        name = ""; emoji = ""; colorHex = "#2ECC71"; pointValue = 1; targetCount = 1
    }

    private func delete(at offsets: IndexSet) {
        guard var f = app.selectedFamily else { return }
        f.categories.remove(atOffsets: offsets)
        Task { await app.saveFamily(f) }
    }
}

struct EditCategoryButton: View {
    @EnvironmentObject var app: AppViewModel
    let category: Category
    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var colorHex: String = "#FFFFFF"
    @State private var pointValue: Int = 1
    @State private var targetCount: Int = 1
    @State private var show = false

    var body: some View {
        Button("Edit") { preload(); show = true }
            .sheet(isPresented: $show) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $name)
                        TextField("Emoji", text: $emoji)
                        TextField("Color #RRGGBB", text: $colorHex)
                        Stepper("Points: \(pointValue)", value: $pointValue, in: 1...100)
                        Stepper("Target: \(targetCount)", value: $targetCount, in: 1...100)
                    }
                    .navigationTitle("Edit Category")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save", action: save) } }
                }
            }
    }

    private func preload() {
        name = category.name
        emoji = category.emoji ?? ""
        colorHex = category.colorHex
        pointValue = category.pointValue
        targetCount = category.targetCount
    }

    private func save() {
        guard var f = app.selectedFamily else { return }
        if let idx = f.categories.firstIndex(where: { $0.id == category.id }) {
            f.categories[idx].name = name
            let e = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
            f.categories[idx].emoji = e.isEmpty ? nil : e
            f.categories[idx].colorHex = colorHex
            f.categories[idx].pointValue = pointValue
            f.categories[idx].targetCount = targetCount
            Task { await app.saveFamily(f) }
        }
        show = false
    }
}
