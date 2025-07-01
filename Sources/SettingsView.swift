import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    Toggle("Premium Features", isOn: $appState.isPremium)
                }
                
                Section("About") {
                    Text("FlirtFrame v1.0")
                    Text("AI-powered conversation starters")
                }
            }
            .navigationTitle("Settings")
        }
    }
}