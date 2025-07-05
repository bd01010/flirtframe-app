import Foundation
#if canImport(Firebase)
import Firebase
#endif

/// Simplified Firebase setup that gracefully handles missing Firebase
public class FirebaseSetup {
    public static let shared = FirebaseSetup()
    
    private var isConfigured = false
    
    private init() {}
    
    public func configure() {
        #if canImport(Firebase)
        // Only configure if Firebase is available
        if !isConfigured {
            FirebaseApp.configure()
            isConfigured = true
            print("✅ Firebase configured successfully")
        }
        #else
        print("⚠️ Firebase SDK not available - running without Firebase")
        #endif
    }
    
    public func isAvailable() -> Bool {
        #if canImport(Firebase)
        return true
        #else
        return false
        #endif
    }
}