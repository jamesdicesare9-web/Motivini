import SwiftUI

struct MainTabsView: View {
    @EnvironmentObject var app: AppViewModel

    private var sessionMember: FamilyMember? {
        guard let fam = app.selectedFamily, let name = app.currentAccount?.displayName else { return nil }
        return fam.members.first { $0.name == name }
    }

    var body: some View {
        if let fam = app.selectedFamily, let member = sessionMember {
            member.role == .child ? AnyView(KidTabsView(member: member, family: fam))
                                  : AnyView(ParentTabsView())
        } else {
            ParentTabsView() // fallback
        }
    }
}

struct ParentTabsView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            ApprovalsView()
                .tabItem { Label("Approvals", systemImage: "checkmark.seal") }
            MembersView()
                .tabItem { Label("Members", systemImage: "person.2") }
            CategoriesView()
                .tabItem { Label("Categories", systemImage: "tag") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

struct KidTabsView: View {
    @EnvironmentObject var app: AppViewModel
    let member: FamilyMember
    let family: Family

    var body: some View {
        TabView {
            MyTasksView(child: member)
                .tabItem { Label("My Tasks", systemImage: "list.bullet") }
            KidLogActivityView(child: member)
                .tabItem { Label("Log", systemImage: "plus.circle") }
            MyPointsView(child: member)
                .tabItem { Label("My Points", systemImage: "trophy") }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { app.signOut() } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
    }
}
