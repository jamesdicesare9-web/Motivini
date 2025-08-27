import SwiftUI

struct ApprovalsView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Approvals").font(.title2).bold()
            if let fam = app.selectedFamily {
                if fam.pendingApprovals.isEmpty {
                    Text("No approvals pending.").foregroundStyle(.secondary)
                } else {
                    List {
                        ForEach(fam.pendingApprovals) { a in
                            ApprovalRow(approval: a)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
        }
        .padding()
    }

    private func delete(at offsets: IndexSet) {
        guard var fam = app.selectedFamily else { return }
        fam.pendingApprovals.remove(atOffsets: offsets)
        Task { await app.saveFamily(fam) }
    }
}

struct ApprovalRow: View {
    @EnvironmentObject var app: AppViewModel
    let approval: Approval

    var body: some View {
        if let fam = app.selectedFamily {
            switch approval.kind {
            case .task:
                if let task = fam.tasks.first(where: { $0.id == approval.taskId }) {
                    row(title: task.title, subtitle: "Task submission",
                        approve: { updateTask(approved: true) },
                        deny: { updateTask(approved: false) })
                }
            case .activity:
                if let member = fam.members.first(where: { $0.id == approval.memberId }),
                   let cat = fam.categories.first(where: { $0.id == approval.categoryId }) {
                    row(title: "\(member.name) → \(cat.name)", subtitle: "Activity log",
                        approve: approveActivity, deny: deny)
                }
            }
        }
    }

    @ViewBuilder
    private func row(title: String, subtitle: String,
                     approve: @escaping () -> Void,
                     deny: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(title).bold()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                Text(approval.submittedAt, style: .date).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            HStack {
                Button("Approve", action: approve).buttonStyle(.borderedProminent)
                Button("Deny", action: deny).buttonStyle(.bordered)
            }
        }
    }

    private func updateTask(approved: Bool) {
        guard var fam = app.selectedFamily else { return }
        if let idx = fam.pendingApprovals.firstIndex(where: { $0.id == approval.id }) {
            fam.pendingApprovals.remove(at: idx)
        }
        if approved, let tidx = fam.tasks.firstIndex(where: { $0.id == approval.taskId }) {
            fam.tasks[tidx].isCompleted = true
            fam.tasks[tidx].completedById = approval.submittedById
            fam.tasks[tidx].completedAt = Date()
            fam.activityLog.append(
                ActivityLogEntry(id: UUID(), date: Date(), memberId: approval.submittedById,
                                 description: "Approved: \(fam.tasks[tidx].title)",
                                 categoryId: fam.tasks[tidx].categoryId)
            )
        }
        Task { await app.saveFamily(fam) }
    }

    private func approveActivity() {
        guard var fam = app.selectedFamily,
              let memberId = approval.memberId, let categoryId = approval.categoryId else { return }
        if let idx = fam.pendingApprovals.firstIndex(where: { $0.id == approval.id }) {
            fam.pendingApprovals.remove(at: idx)
        }
        if let p = fam.progress.firstIndex(where: { $0.memberId == memberId && $0.categoryId == categoryId }) {
            fam.progress[p].count += 1
        } else {
            fam.progress.append(ProgressCounter(id: UUID(), memberId: memberId, categoryId: categoryId, count: 1))
        }
        if let cat = fam.categories.first(where: { $0.id == categoryId }),
           let p = fam.progress.firstIndex(where: { $0.memberId == memberId && $0.categoryId == categoryId }) {
            while fam.progress[p].count >= cat.targetCount {
                fam.progress[p].count -= cat.targetCount
                fam.memberPoints[memberId, default: 0] += max(0, cat.pointValue)
                fam.activityLog.append(ActivityLogEntry(id: UUID(), date: Date(), memberId: memberId,
                                                        description: "+\(cat.pointValue) pts for \(cat.name)",
                                                        categoryId: categoryId))
            }
        }
        Task { await app.saveFamily(fam) }
    }

    private func deny() {
        guard var fam = app.selectedFamily else { return }
        if let idx = fam.pendingApprovals.firstIndex(where: { $0.id == approval.id }) {
            fam.pendingApprovals.remove(at: idx)
        }
        Task { await app.saveFamily(fam) }
    }
}
