//
//  SettingsView.swift
//  Photix
//
//  Created by Dean Andreakis on 12/6/24.
//  Copyright © 2024 deanware. All rights reserved.
//

import SwiftUI
import StoreKit
import MessageUI

struct SettingsView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var dependencies: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingMailComposer = false
    @State private var showingPurchaseConfirmation = false
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 30) {
                    Spacer(minLength: 40)
                    
                    // Main description text
                    VStack(spacing: 20) {
                        Text("OilPaintPlus (v4.0) relies on your support to fund its development. If you find it useful to enhance your pictures, please consider supporting the app by leaving a tip in our Tip Jar.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Tip Jar buttons
                    if storeManager.isLoading {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 100)
                    } else if storeManager.products.isEmpty {
                        // Show mock tip buttons when products aren't available
                        HStack(spacing: 20) {
                            MockTipButton(title: "Generous", price: "$0.99")
                            MockTipButton(title: "Massive", price: "$1.99")
                            MockTipButton(title: "Amazing", price: "$4.99")
                        }
                        .padding(.horizontal, 20)
                    } else {
                        HStack(spacing: 20) {
                            ForEach(storeManager.products.prefix(3), id: \.id) { product in
                                TipJarButton(
                                    product: product,
                                    isPurchased: storeManager.isPurchased(product.id)
                                ) {
                                    selectedProduct = product
                                    showingPurchaseConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                
                // Email icon at bottom
                VStack {
                    Button(action: {
                        if MFMailComposeViewController.canSendMail() {
                            showingMailComposer = true
                        } else {
                            alertTitle = "Mail Not Available"
                            alertMessage = "Please configure Mail app to send emails."
                            showingAlert = true
                        }
                    }) {
                        Image(systemName: "envelope")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposeView()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog(
                selectedProduct?.displayName ?? "",
                isPresented: $showingPurchaseConfirmation
            ) {
                Button("Cancel", role: .cancel) { }
                Button("Buy \(selectedProduct?.displayPrice ?? "")") {
                    purchaseProduct()
                }
            } message: {
                if let product = selectedProduct {
                    Text("\(product.displayName): \(product.description)")
                }
            }
            .overlay {
                if isPurchasing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("Please wait...")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                }
            }
        }
    }
    
    private func purchaseProduct() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            let success = await storeManager.purchase(product)
            
            await MainActor.run {
                isPurchasing = false
                
                if success {
                    alertTitle = "Thank You!"
                    alertMessage = "Your tip is greatly appreciated!"
                    showingAlert = true
                } else if let error = storeManager.error {
                    alertTitle = "Purchase Failed"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct MockTipButton: View {
    let title: String
    let price: String
    
    var body: some View {
        Button(action: {
            // Show alert that this is a demo
        }) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text("Tip of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(price)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}

struct TipJarButton: View {
    let product: Product
    let isPurchased: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(getTipName())
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text("Tip of")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isPurchased {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Text(product.displayPrice)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .disabled(isPurchased)
        .opacity(isPurchased ? 0.7 : 1.0)
    }
    
    private func getTipName() -> String {
        // Map product IDs to tip names based on common patterns
        let price = product.displayPrice
        if price.contains("0.99") {
            return "Generous"
        } else if price.contains("1.99") {
            return "Massive"
        } else if price.contains("4.99") {
            return "Amazing"
        } else {
            return product.displayName
        }
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject("OilPaintPlus Support")
        composer.setToRecipients(["dean@deanware.com"])
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager.shared)
        .environmentObject(DependencyContainer.shared)
}