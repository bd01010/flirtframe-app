import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage1()
                    .tag(0)
                
                OnboardingPage2()
                    .tag(1)
                
                OnboardingPage3()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            
            HStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                }
            }
            .padding()
            
            Button(action: {
                if currentPage < 2 {
                    currentPage += 1
                } else {
                    appState.completeOnboarding()
                }
            }) {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct OnboardingPage1: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to FlirtFrame")
                .font(.largeTitle)
                .bold()
            
            Text("Generate witty conversation starters from photos of your surroundings")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct OnboardingPage2: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("AI-Powered Observations")
                .font(.largeTitle)
                .bold()
            
            Text("Our AI analyzes your photos to create unique, contextual conversation starters")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct OnboardingPage3: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Start Real Conversations")
                .font(.largeTitle)
                .bold()
            
            Text("Perfect for bars, parties, events - anywhere you want to break the ice")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}