import SwiftUI

@main
struct MotiviniApp: App {
    @StateObject private var app = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
        }
    }
}
