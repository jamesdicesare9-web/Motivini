import SwiftUI

@main
struct MotiviniApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .preferredColorScheme(.light)
        }
    }
}
// linked OK
