import SwiftUI
import Firebase

@main
struct FlirtFrameApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(firebaseManager)
        }
    }
}