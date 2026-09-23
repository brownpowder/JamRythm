import Foundation
import SwiftUI
import Combine
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    @Published var products: [Product] = []
    
    private let premiumProductID = "JamRythm.premium"
    var updateListenerTask: Task<Void, Error>? = nil
    
    var isUnlocked: Bool {
        #if DEBUG
        if UserDefaults.standard.object(forKey: "debugPremiumUnlocked") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "debugPremiumUnlocked")
        #else
        return isPremium
        #endif
    }
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func togglePremium() {
        isPremium.toggle()
    }
    
    func requestProducts() async {
        do {
            products = try await Product.products(for: [premiumProductID])
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
    }
    
    func purchasePremium() {
        Task {
            guard let product = products.first(where: { $0.id == premiumProductID }) else {
                print("Premium product not found.")
                // To allow testing when App Store Connect isn't syncing properly in debug
                #if DEBUG
                self.isPremium = true
                #endif
                return
            }
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    let transaction = try self.checkVerified(verification)
                    await transaction.finish()
                    await self.updateCustomerProductStatus()
                case .userCancelled, .pending:
                    break
                @unknown default:
                    break
                }
            } catch {
                print("Failed to purchase: \(error)")
            }
        }
    }
    
    func restorePurchases() {
        Task {
            try? await AppStore.sync()
        }
    }
    
    private func updateCustomerProductStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try self.checkVerified(result)
                if transaction.productID == premiumProductID {
                    isPremium = true
                }
            } catch {
                print("Transaction failed verification")
            }
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updateCustomerProductStatus()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
