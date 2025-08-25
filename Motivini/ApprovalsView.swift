import SwiftUI
import SwiftData

struct ApprovalsView: View {
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<Completion> { $0.approved == nil },
        sort: [SortDescriptor(\Completion.date, order: .reverse)]
    ) private var pending: [Completion]

    var body: some View {
        ParentGate {
            NavigationStack {
                List {
                    if pending.isEmpty {
                        ContentUnavailableView("No approvals waiting", systemImage: "checkmark.seal")
                    } else {
                        ForEach(pending) { c in
                            HStack {
                                Text(c.member?.avatarEmoji ?? "🙂")
                                VStack(alignment: .leading) {
                                    Text(c.member?.name ?? "Unknown").font(.headline)
                                    Text("\(c.category?.icon ?? "✅") \(c.category?.name ?? "Activity")")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                HStack(spacing: 12) {
                                    Button("Decline") {
                                        c.approved = false
                                        try? context.save()
                                        Haptics.warning()
                                    }.buttonStyle(.bordered)

                                    Button("Approve") {
                                        c.approved = true
                                        try? context.save()
                                        try? PointsEngine.awardIfThresholdCrossed(for: c, in: context)
                                        try? context.save()
                                        Haptics.success()
                                    }.buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Parent Approvals")
            }
        }
    }
}
