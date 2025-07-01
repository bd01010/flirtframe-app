import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "4ECDC4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                    }
                    
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        Text("Unlock Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Get unlimited openers and exclusive features")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(
                            icon: "infinity",
                            title: "Unlimited Analyses",
                            description: "Analyze as many photos as you want"
                        )
                        
                        FeatureRow(
                            icon: "brain.head.profile",
                            title: "AI-Powered Insights",
                            description: "Get detailed photo analysis and context"
                        )
                        
                        FeatureRow(
                            icon: "bubble.left.and.bubble.right",
                            title: "Custom Opener Styles",
                            description: "Choose from 8 different opener styles"
                        )
                        
                        FeatureRow(
                            icon: "person.crop.circle.badge.checkmark",
                            title: "Instagram Integration",
                            description: "Import profiles for personalized openers"
                        )
                        
                        FeatureRow(
                            icon: "clock.arrow.circlepath",
                            title: "Opener History",
                            description: "Access all your past openers anytime"
                        )
                        
                        FeatureRow(
                            icon: "star.circle",
                            title: "Priority Support",
                            description: "Get help when you need it"
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 30)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Pricing options
                    VStack(spacing: 15) {
                        ForEach(purchaseManager.products) { product in
                            PricingOption(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onTap: { selectedProduct = product }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase button
                    Button(action: purchaseProduct) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedProduct != nil ? Color.white : Color.white.opacity(0.3))
                        .foregroundColor(selectedProduct != nil ? Color(hex: "FF6B6B") : Color.white.opacity(0.7))
                        .cornerRadius(16)
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal)
                    
                    // Terms and restore
                    VStack(spacing: 10) {
                        Button("Restore Purchases") {
                            Task {
                                await purchaseManager.restorePurchases()
                            }
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        
                        HStack(spacing: 20) {
                            Link("Terms of Service", destination: URL(string: "https://flirtframe.app/terms")!)
                            Link("Privacy Policy", destination: URL(string: "https://flirtframe.app/privacy")!)
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func purchaseProduct() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let result = await purchaseManager.purchase(product)
                
                switch result {
                case .success:
                    dismiss()
                case .userCancelled:
                    isPurchasing = false
                case .pending:
                    isPurchasing = false
                    errorMessage = "Purchase is pending. Please check back later."
                    showError = true
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct PricingOption: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .white)
                    
                    if let description = product.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(isSelected ? Color.gray : .white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? Color(hex: "FF6B6B") : .white)
                    
                    if let subscriptionPeriod = product.subscription?.subscriptionPeriod {
                        Text(periodText(for: subscriptionPeriod))
                            .font(.caption)
                            .foregroundColor(isSelected ? Color.gray : .white.opacity(0.8))
                    }
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(hex: "4ECDC4") : .white.opacity(0.5))
            }
            .padding()
            .background(isSelected ? Color.white : Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func periodText(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return period.value == 1 ? "per day" : "per \(period.value) days"
        case .week:
            return period.value == 1 ? "per week" : "per \(period.value) weeks"
        case .month:
            return period.value == 1 ? "per month" : "per \(period.value) months"
        case .year:
            return period.value == 1 ? "per year" : "per \(period.value) years"
        @unknown default:
            return ""
        }
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}