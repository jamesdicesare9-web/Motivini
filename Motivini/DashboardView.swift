import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var selectedMember: FamilyMember? = nil
    @State private var showCompletions = true

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Dashboard").font(.title).bold()
                Spacer()
                Toggle("Completions", isOn: $showCompletions)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if let family = app.selectedFamily {
                content(family: family)
            } else {
                Text("No family selected").foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func content(family: Family) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Filter:")
                Menu(selectedMember?.name ?? "All Children") {
                    Button("All Children") { selectedMember = nil }
                    ForEach(family.members.filter { $0.role == .child }) { m in
                        Button(m.name) { selectedMember = m }
                    }
                }
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(family.categories) { cat in
                    CategoryCard(category: cat, memberFilter: selectedMember, showCompletions: showCompletions)
                }
            }

            QuickAddTask()
            QuickLogActivity()
        }
    }
}

struct CategoryCard: View {
    @EnvironmentObject var app: AppViewModel
    let category: Category
    let memberFilter: FamilyMember?
    let showCompletions: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(category.emoji ?? "⬜️").font(.largeTitle); Text(category.name).bold(); Spacer() }
            HStack(spacing: 8) {
                Text("Pts: \(category.pointValue)")
                Text("Target: \(category.targetCount)")
            }.font(.caption).foregroundStyle(.secondary)

            if let fam = app.selectedFamily, showCompletions {
                let tasks = fam.tasks.filter { $0.categoryId == category.id }
                let filtered = memberFilter == nil ? tasks : tasks.filter { $0.assigneeId == memberFilter!.id }
                let completed = filtered.filter { $0.isCompleted }.count
                let total = filtered.count
                ProgressView(value: total == 0 ? 0 : Double(completed) / Double(max(1,total)))
                Text("\(completed)/\(total) completed").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(14)
    }
}

// QuickLogActivity & QuickAddTask (parent helpers)

struct QuickLogActivity: View {
    @EnvironmentObject var app: AppViewModel
    @State private var selectedCategory: Category? = nil
    @State private var selectedMember: FamilyMember? = nil

    var body: some View {
        GroupBox("Log Activity") {
            if let fam = app.selectedFamily, let acc = app.currentAccount {
                VStack(spacing: 8) {
                    HStack {
                        Menu(selectedCategory?.name ?? "Category") {
                            ForEach(fam.categories) { c in Button(c.name) { selectedCategory = c } }
                        }
                        Menu(selectedMember?.name ?? defaultMemberName(fam: fam, accName: acc.displayName)) {
                            ForEach(fam.members) { m in Button(m.name) { selectedMember = m } }
                        }
                        Spacer()
                        Button("Log") { logActivity(fam: fam, accName: acc.displayName) }
                            .disabled(selectedCategory == nil)
                    }
                }
            }
        }
    }

    private func currentMember(in fam: Family, accName: String) -> FamilyMember? {
        fam.members.first(where: { $0.name == accName })
    }
    private func defaultMemberName(fam: Family, accName: String) -> String {
        currentMember(in: fam, accName: accName)?.name ?? "Choose Member"
    }

    private func logActivity(fam: Family, accName: String) {
        guard let cat = selectedCategory else { return }
        let member = selectedMember ?? currentMember(in: fam, accName: accName)
        guard let target = member else { return }
        var f = fam

        if target.role == .child && accName == target.name {
            f.pendingApprovals.append(Approval(id: UUID(), kind: .activity, taskId: nil,
                                               memberId: target.id, categoryId: cat.id,
                                               submittedById: target.id, submittedAt: Date()))
            f.activityLog.append(ActivityLogEntry(id: UUID(), date: Date(), memberId: target.id,
                                                  description: "Activity submitted: \(cat.name)",
                                                  categoryId: cat.id))
        } else {
            applyActivity(&f, memberId: target.id, categoryId: cat.id)
        }
        Task { await app.saveFamily(f) }
        selectedCategory = nil
    }

    private func applyActivity(_ fam: inout Family, memberId: UUID, categoryId: UUID) {
        if let i = fam.progress.firstIndex(where: { $0.memberId == memberId && $0.categoryId == categoryId }) {
            fam.progress[i].count += 1
        } else {
            fam.progress.append(ProgressCounter(id: UUID(), memberId: memberId, categoryId: categoryId, count: 1))
        }
        guard let cat = fam.categories.first(where: { $0.id == categoryId }),
              let p = fam.progress.firstIndex(where: { $0.memberId == memberId && $0.categoryId == categoryId })
        else { return }

        while fam.progress[p].count >= cat.targetCount {
            fam.progress[p].count -= cat.targetCount
            fam.memberPoints[memberId, default: 0] += max(0, cat.pointValue)
            fam.activityLog.append(ActivityLogEntry(id: UUID(), date: Date(), memberId: memberId,
                                                    description: "+\(cat.pointValue) pts for \(cat.name)",
                                                    categoryId: categoryId))
        }
    }
}

struct QuickAddTask: View {
    @EnvironmentObject var app: AppViewModel
    @State private var title = ""
    @State private var selectedCategory: Category? = nil
    @State private var selectedAssignee: FamilyMember? = nil

    var body: some View {
        GroupBox("Quick Task") {
            if let fam = app.selectedFamily {
                VStack(spacing: 8) {
                    TextField("Task title", text: $title).textFieldStyle(.roundedBorder)
                    HStack {
                        Menu(selectedCategory?.name ?? "Category") {
                            ForEach(fam.categories) { c in
                                Button(action: { selectedCategory = c }) { Text(c.name) }
                            }
                        }
                        Menu(selectedAssignee?.name ?? "Assignee (optional)") {
                            ForEach(fam.members) { m in Button(m.name) { selectedAssignee = m } }
                            Button("None") { selectedAssignee = nil }
                        }
                        Spacer()
                        Button("Add") { add(fam: fam) }
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || selectedCategory == nil)
                    }
                }
            }
        }
    }

    private func add(fam: Family) {
        var f = fam
        let new = MVTask(id: UUID(), title: title, categoryId: selectedCategory!.id,
                         assigneeId: selectedAssignee?.id, dueDate: nil,
                         isCompleted: false, completedById: nil, completedAt: nil)
        f.tasks.append(new)
        Task { await app.saveFamily(f) }
        title = ""; selectedCategory = nil; selectedAssignee = nil
    }
}
