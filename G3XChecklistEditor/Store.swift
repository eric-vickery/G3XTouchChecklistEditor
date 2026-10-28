//
//  Store.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/31/24.
//

import StoreKit

@MainActor final class Store: ObservableObject {
    @Published var products: [Product] = []
    @Published var activeTransactions: Set<StoreKit.Transaction> = []
    
    init() {}
    
    func fetchProducts() async {
        do {
            products = try await Product.products(for: ["com.serenitymountainranch.G3XTouchChecklistEditor.unlock"])
        } catch {
            products = []
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            if let transaction = try? verificationResult.payloadValue {
                activeTransactions.insert(transaction)
                await transaction.finish()
            }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }
}
