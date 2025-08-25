import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Member.name)]) private var members: [Member]
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]
    @Query(filter: #Predicate<Completion> { $0.approved == nil })
    private var pendingApprovals: [Completion]

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }

            SeriesListView()
                .tabItem { Label("Log", systemImage: "checkmark.circle") }

            ApprovalsView()
                .tabItem { Label("Approve", systemImage: "hand.thumbsup") }
                .badge(pendingApprovals.count)

            RewardsView()
                .tabItem { Label("Rewards", systemImage: "creditcard") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .onAppear { seedIfNeeded() }
    }

    private func seedIfNeeded() {
        guard members.isEmpty || categories.isEmpty else { return }

        let mom = Member(name: "Mom", role: .parent, avatarEmoji: "👩‍🍼")
        let dad = Member(name: "Dad", role: .parent, avatarEmoji: "👨‍🍼")
        let kid = Member(name: "Ava", role: .child,  avatarEmoji: "🧒")

        let makeBed    = Category(name: "Make Bed",        icon: "🛏️", targetCount: 5, pointsPerAward: 2)
        let dishwasher = Category(name: "Load Dishwasher", icon: "🍽️", targetCount: 5, pointsPerAward: 2)
        let homework   = Category(name: "Homework",        icon: "📚", targetCount: 5, pointsPerAward: 2)
        let teeth      = Category(name: "Brush Teeth",     icon: "🪥", targetCount: 5, pointsPerAward: 2)
        let clearTable = Category(name: "Clear Table",     icon: "🍽️", targetCount: 5, pointsPerAward: 2)

        [mom, dad, kid].forEach { context.insert($0) }
        [makeBed, dishwasher, homework, teeth, clearTable].forEach { context.insert($0) }

        try? context.save()
    }
}
