import SwiftUI

@main
struct FlirtFrameApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Configure Firebase if available
        FirebaseSetup.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}