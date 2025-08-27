import SwiftUI

struct TaskRow: View {
    @EnvironmentObject var app: AppViewModel
    let task: MVTask

    private var category: Category? {
        app.selectedFamily?.categories.first(where: { $0.id == task.categoryId })
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).bold()
                if let category { Text(category.name).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Complete") { completeTapped() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 6)
    }

    private func completeTapped() {
        guard var fam = app.selectedFamily else { return }
        guard let currentName = app.currentAccount?.displayName,
              let currentMember = fam.members.first(where: { $0.name == currentName }) else { return }

        if currentMember.role == .child {
            // Child completion -> requires approval
            fam.pendingApprovals.append(
                Approval(id: UUID(),
                         kind: .task,
                         taskId: task.id,
                         memberId: currentMember.id,
                         categoryId: task.categoryId,
                         submittedById: currentMember.id,
                         submittedAt: Date())
            )
            fam.activityLog.append(
                ActivityLogEntry(id: UUID(), date: Date(), memberId: currentMember.id,
                                 description: "Task submitted: \(task.title)", categoryId: task.categoryId)
            )
        } else {
            // Parent/admin -> immediate completion
            if let idx = fam.tasks.firstIndex(where: { $0.id == task.id }) {
                fam.tasks[idx].isCompleted = true
                fam.tasks[idx].completedById = currentMember.id
                fam.tasks[idx].completedAt = Date()
            }
            fam.activityLog.append(
                ActivityLogEntry(id: UUID(), date: Date(), memberId: currentMember.id,
                                 description: "Completed: \(task.title)", categoryId: task.categoryId)
            )
        }

        Task { await app.saveFamily(fam) }
    }
}
