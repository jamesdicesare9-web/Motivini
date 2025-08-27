import SwiftUI

struct DashboardTaskList: View {
    @EnvironmentObject var app: AppViewModel
    let memberFilter: FamilyMember?

    var body: some View {
        if let fam = app.selectedFamily {
            let tasks = fam.tasks
                .filter { memberFilter == nil ? true : $0.assigneeId == memberFilter!.id }

            List {
                ForEach(tasks) { t in
                    TaskRow(task: t)
                }
            }
        } else {
            Text("No family selected").foregroundStyle(.secondary)
        }
    }
}
