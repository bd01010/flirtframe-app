import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Skip AI model download - using OpenAI API instead
        showMainApp()
        
        window?.makeKeyAndVisible()
        return true
    }
    
    private func showMainApp() {
        let appState = AppState()
        let cameraScreen = CameraScreen()
            .environmentObject(appState)
        window?.rootViewController = UIHostingController(rootView: cameraScreen)
    }
}