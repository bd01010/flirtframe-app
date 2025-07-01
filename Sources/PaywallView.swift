import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Unlock Premium")
                .font(.largeTitle)
                .bold()
            
            Text("Get unlimited conversation starters")
                .font(.headline)
            
            Button("Subscribe - $4.99/month") {
                // Handle subscription
                appState.isPremium = true
                isPresented = false
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Restore Purchase") {
                // Handle restore
            }
            
            Button("Maybe Later") {
                isPresented = false
            }
        }
        .padding()
    }
}