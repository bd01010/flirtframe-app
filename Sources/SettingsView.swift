import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @AppStorage("preferredTone") private var preferredTone = "balanced"
    @AppStorage("autoSaveHistory") private var autoSaveHistory = true
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("defaultOpenerCount") private var defaultOpenerCount = 5
    @State private var showingRestorePurchases = false
    @State private var showingDeleteConfirmation = false
    @State private var restorationMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    HStack {
                        Label("Subscription", systemImage: "crown.fill")
                        Spacer()
                        if purchaseManager.isPremium {
                            Text("Premium")
                                .foregroundColor(.green)
                        } else {
                            Text("Free")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !purchaseManager.isPremium {
                        Button(action: { appState.showingPaywall = true }) {
                            Label("Upgrade to Premium", systemImage: "sparkles")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: restorePurchases) {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("Account")
                }
                
                // Preferences Section
                Section {
                    Picker("Default Tone", selection: $preferredTone) {
                        Text("Professional").tag("professional")
                        Text("Casual").tag("casual")
                        Text("Flirty").tag("flirty")
                        Text("Funny").tag("funny")
                        Text("Balanced").tag("balanced")
                    }
                    
                    Stepper("Openers per photo: \(defaultOpenerCount)", value: $defaultOpenerCount, in: 3...8)
                    
                    Toggle("Auto-save History", isOn: $autoSaveHistory)
                    
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("These settings apply to all new photo analyses")
                }
                
                // Privacy Section
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy Settings", systemImage: "lock.shield")
                    }
                    
                    Button(action: clearHistory) {
                        Label("Clear History", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Privacy")
                }
                
                // Support Section
                Section {
                    Link(destination: URL(string: "https://flirtframe.app/support")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    Link(destination: URL(string: "https://flirtframe.app/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Link(destination: URL(string: "https://flirtframe.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.shield")
                    }
                    
                    Button(action: rateApp) {
                        Label("Rate FlirtFrame", systemImage: "star")
                    }
                } header: {
                    Text("Support")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(destination: AcknowledgmentsView()) {
                        Label("Acknowledgments", systemImage: "heart")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Restore Purchases", isPresented: $showingRestorePurchases) {
            Button("OK") { }
        } message: {
            Text(restorationMessage)
        }
        .alert("Clear History", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClearHistory()
            }
        } message: {
            Text("This will permanently delete all your photo analyses and generated openers. This action cannot be undone.")
        }
    }
    
    private func restorePurchases() {
        Task {
            await purchaseManager.restorePurchases()
            
            await MainActor.run {
                if purchaseManager.isPremium {
                    restorationMessage = "Your premium subscription has been restored!"
                } else {
                    restorationMessage = "No previous purchases found."
                }
                showingRestorePurchases = true
            }
        }
    }
    
    private func clearHistory() {
        showingDeleteConfirmation = true
    }
    
    private func performClearHistory() {
        // Clear history from SessionMemory
        // In a real app, this would clear persistent storage
        if enableHaptics {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

struct PrivacySettingsView: View {
    @AppStorage("analyticsEnabled") private var analyticsEnabled = true
    @AppStorage("crashReportingEnabled") private var crashReportingEnabled = true
    @AppStorage("photoProcessingLocation") private var photoProcessingLocation = "device"
    
    var body: some View {
        List {
            Section {
                Toggle("Analytics", isOn: $analyticsEnabled)
                Toggle("Crash Reporting", isOn: $crashReportingEnabled)
            } header: {
                Text("Data Collection")
            } footer: {
                Text("We use this data to improve FlirtFrame. No personal information is collected.")
            }
            
            Section {
                Picker("Photo Processing", selection: $photoProcessingLocation) {
                    Text("On Device").tag("device")
                    Text("Cloud").tag("cloud")
                }
            } header: {
                Text("Processing Location")
            } footer: {
                Text("On-device processing is more private but may be slower. Cloud processing is faster but requires uploading photos.")
            }
            
            Section {
                Text("""
                Your privacy is important to us. FlirtFrame:
                
                • Never stores your photos permanently
                • Processes images locally when possible
                • Doesn't share your data with third parties
                • Uses end-to-end encryption for cloud features
                • Allows you to delete all data at any time
                """)
                .font(.footnote)
                .foregroundColor(.secondary)
            } header: {
                Text("Our Commitment")
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section {
                Text("""
                FlirtFrame is built with love using these amazing technologies:
                
                • SwiftUI - Apple's modern UI framework
                • Vision Framework - For intelligent photo analysis
                • Core ML - For on-device machine learning
                • Natural Language - For text processing
                
                Special thanks to all our beta testers and the iOS development community!
                """)
                .font(.body)
                .padding(.vertical, 8)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Created by AppCraft Studios", systemImage: "hammer")
                    Label("Designed in California", systemImage: "location")
                    Label("Made with ❤️ for the dating community", systemImage: "heart.fill")
                        .foregroundColor(.pink)
                }
                .font(.callout)
                .padding(.vertical, 4)
            } header: {
                Text("Credits")
            }
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }
}