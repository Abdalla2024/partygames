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
            await listenForTransactionUpdates()
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
    
    // MARK: - Transaction Updates Listener
    
    /// Listen for transaction updates that occur outside of direct purchases
    /// This ensures we don't miss purchases completed on other devices or background renewals
    private func listenForTransactionUpdates() async {
        // Create a task that continuously listens for transaction updates
        Task {
            for await verificationResult in Transaction.updates {
                await handleTransactionUpdate(verificationResult)
            }
        }
    }
    
    /// Handle individual transaction updates
    @MainActor
    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let transaction):
            // Only process transactions that haven't been revoked
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
                print("Transaction update processed: \(transaction.productID)")
            } else {
                // Remove revoked transactions
                purchasedProductIDs.remove(transaction.productID)
                print("Transaction revoked: \(transaction.productID)")
            }
            
            // Finish the transaction to acknowledge receipt
            await transaction.finish()
            
        case .unverified(let transaction, let verificationError):
            print("Unverified transaction update: \(transaction.productID), error: \(verificationError)")
            // Don't finish unverified transactions
        }
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
    
    /// Sync UserPreferences with current StoreKit entitlements
    /// This ensures UserPreferences reflects actual subscription status from StoreKit
    @MainActor
    func syncUserPreferencesWithStoreKit(_ userPreferences: UserPreferences) async {
        print("🔄 Starting sync of UserPreferences with StoreKit entitlements...")
        
        // Get current StoreKit premium access status
        let currentStoreKitStatus = hasPremiumAccess
        let currentUserPrefsStatus = userPreferences.hasPremiumAccess
        
        print("📊 Sync Status - StoreKit: \(currentStoreKitStatus), UserPreferences: \(currentUserPrefsStatus)")
        
        // Check if sync is needed
        if currentStoreKitStatus != currentUserPrefsStatus {
            print("⚠️ Status mismatch detected - updating UserPreferences to match StoreKit")
            
            if currentStoreKitStatus {
                // User has premium access in StoreKit - update UserPreferences
                if purchasedProductIDs.contains(ProductID.lifetime) {
                    userPreferences.updateSubscription(
                        type: UserPreferences.SubscriptionType.lifetime,
                        hasPremium: true
                    )
                    print("✅ Updated UserPreferences to Lifetime Premium")
                } else if purchasedProductIDs.contains(ProductID.weekly) {
                    let expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
                    userPreferences.updateSubscription(
                        type: UserPreferences.SubscriptionType.weekly,
                        hasPremium: true,
                        expirationDate: expirationDate
                    )
                    print("✅ Updated UserPreferences to Weekly Premium (expires: \(expirationDate?.formatted() ?? "Unknown"))")
                }
            } else {
                // No premium access in StoreKit - remove from UserPreferences
                userPreferences.hasPremiumAccess = false
                userPreferences.subscriptionType = nil
                userPreferences.subscriptionDate = nil
                userPreferences.subscriptionExpirationDate = nil
                userPreferences.updatedAt = Date()
                print("✅ Removed premium access from UserPreferences (no active StoreKit entitlements)")
            }
        } else {
            print("✅ UserPreferences already in sync with StoreKit - no update needed")
        }
        
        print("🔄 UserPreferences sync completed")
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