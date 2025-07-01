import StoreKit
import Foundation

class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published var isPremium = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIds = ["com.flirtframe.premium.monthly", "com.flirtframe.premium.yearly"]
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID.contains("premium") {
                    purchasedProductIDs.insert(transaction.productID)
                    isPremium = true
                }
            } catch {
                print("Transaction verification failed")
            }
        }
    }
    
    func restorePurchases() async {
        await updatePurchasedProducts()
    }
}

enum PurchaseError: Error {
    case failedVerification
}