//
//  ProductSheetView.swift
//  G3X Touch Checklist Editor
//
//  Created by Eric Vickery on 1/30/24.
//

import SwiftUI
import StoreKit

struct ProductSheetView: View {
    @StateObject var store = Store()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack
        {
            if store.products.isEmpty
            {
                ProgressView()
            }
            else
            {
                Text("Fully unlock all the functionality including removing the 3 item limit on groups and checklists")
                    .multilineTextAlignment(.center)
                ForEach(store.products, id: \.id) { product in
                    Button
                    {
                        Task
                        {
                            try await store.purchase(product)
                        }
                    }
                label:
                    {
                        VStack
                        {
                            Text(verbatim: product.displayName)
                                .font(.headline)
                            Text(verbatim: product.displayPrice)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
            Button("Done")
            {
                dismiss()
            }
        }
        .padding()
        .task {
            await store.fetchProducts()
        }
    }
}
