import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppViewModel

    var body: some View {
        Group {
            if app.currentAccount == nil {
                AuthFlowView()
            } else if app.selectedFamily == nil {
                FamilyPickerView()
            } else {
                MainTabsView()
            }
        }
    }
}
