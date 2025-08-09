//
//  StoreKitManager.swift
//  Party Games
//
//  Created by Claude on 8/9/25.
//

import Foundation
import StoreKit
import SwiftData

/// StoreKit manager for handling subscription purchases and premium status
@Observable
final class StoreKitManager {
    
    // MARK: - Product IDs
    private enum ProductID {
        static let weekly = "weekly_399"
        static let lifetime = "lifetimeplan"
    }
    
    // MARK: - Properties
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var errorMessage: String?
    
    // Computed properties for easy access
    var weeklyProduct: Product? {
        products.first { $0.id == ProductID.weekly }
    }
    
    var lifetimeProduct: Product? {
        products.first { $0.id == ProductID.lifetime }
    }
    
    var hasPremiumAccess: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    // MARK: - Initialization
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    // MARK: - Product Loading
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await Product.products(for: [ProductID.weekly, ProductID.lifetime])
            self.products = products
            print("Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Management
    @MainActor
    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verificationResult):
                if await handleVerificationResult(verificationResult) {
                    purchasedProductIDs.insert(product.id)
                    print("Successfully purchased: \(product.id)")
                }
            case .userCancelled:
                print("User cancelled purchase")
            case .pending:
                print("Purchase is pending")
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("Purchase error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Restoration
    @MainActor
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("Restored purchases")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("Restore error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func handleVerificationResult(_ verificationResult: VerificationResult<Transaction>) async -> Bool {
        switch verificationResult {
        case .verified(let transaction):
            await transaction.finish()
            return true
        case .unverified:
            return false
        }
    }
    
    @MainActor
    private func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.revocationDate == nil {
                    purchasedProducts.insert(transaction.productID)
                }
            case .unverified:
                break
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
    }
    
    // MARK: - User Preferences Integration
    func updateUserPreferences(_ userPreferences: UserPreferences) {
        let hasPremium = hasPremiumAccess
        userPreferences.hasPremiumAccess = hasPremium
        
        if hasPremium {
            // Determine subscription type
            if purchasedProductIDs.contains(ProductID.lifetime) {
                userPreferences.updateSubscription(type: UserPreferences.SubscriptionType.lifetime)
            } else if purchasedProductIDs.contains(ProductID.weekly) {
                // For weekly subscription, set expiration date to 7 days from now
                let expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                userPreferences.updateSubscription(
                    type: UserPreferences.SubscriptionType.weekly,
                    expirationDate: expirationDate
                )
            }
        }
    }
    
    // MARK: - Product Information
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    var weeklyDisplayPrice: String {
        weeklyProduct?.displayPrice ?? "$3.99"
    }
    
    var lifetimeDisplayPrice: String {
        lifetimeProduct?.displayPrice ?? "$19.99"
    }
}